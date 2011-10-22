import SimpleOpenNI.*;
import processing.serial.*;
Serial pen15;

boolean use_recording = false;

SimpleOpenNI      context;

// NITE
XnVSessionManager sessionManager;
XnVFlowRouter     flowRouter;

PointDrawer       pointDrawer;

ArrayList change = new ArrayList();
int _maxChange = 20;
int lastChange = 0;

void initializePen15()
{
    if(Serial.list().length == 0) {
	println("No serial ports found!");
	exit();
	return;
    }
    pen15 = new Serial(this, Serial.list()[0], 9600);
}

void setup()
{
    context = new SimpleOpenNI(this);

    // mirror is by default enabled
    //context.setMirror(true);
    if(use_recording) {
	String f = selectInput();
	if(f == null) {
	    println("No file selected, exiting");
	    exit();
	    return;
	}
	
	//String f = "/home/qdot/NedLensSideAngle2.oni";
	if( context.openFileRecording(f) == false) {
	    println("can't find recording !!!!");
	    exit();
	    return;
	}
	context.enableScene();
	println("opening file");
    }
    else {
	// enable depthMap generation 
	context.enableDepth();	
    }

    //initializePen15();
    context.enableHands();
    context.enableGesture();
    sessionManager = context.createSessionManager("Wave", "RaiseHand");

    pointDrawer = new PointDrawer();
    flowRouter = new XnVFlowRouter();
    flowRouter.SetActive(pointDrawer);

    sessionManager.AddListener(flowRouter);

    size(context.depthWidth(), context.depthHeight());
    smooth();
}

void draw()
{
    background(200,0,0);
    // update the cam
    context.update();

    // update nite
    context.update(sessionManager);

    // draw depthImageMap
    image(context.depthImage(),0,0);

    // draw the list
    pointDrawer.draw();
}

void keyPressed()
{
    switch(key)
	{
	case 'e':
	    // end sessions
	    sessionManager.EndSession();
	    println("end session");
	    break;
	}
}

/////////////////////////////////////////////////////////////////////////////////////////////////////
// session callbacks

void onStartSession(PVector pos)
{
    println("onStartSession: " + pos);
}

void onEndSession()
{
    println("onEndSession: ");
}

void onFocusSession(String strFocus,PVector pos,float progress)
{
    println("onFocusSession: focus=" + strFocus + ",pos=" + pos + ",progress=" + progress);
}


/////////////////////////////////////////////////////////////////////////////////////////////////////
// PointDrawer keeps track of the handpoints

class PointDrawer extends XnVPointControl
{
    HashMap    _pointLists;
    int        _maxPoints;
    ArrayList _times;
    color[]    _colorList = { color(255,0,0),color(0,255,0),color(0,0,255),color(255,255,0)};

    public PointDrawer()
    {
	_maxPoints = 30;
	_pointLists = new HashMap();
	_times = new ArrayList();
    }

    public void OnPointCreate(XnVHandPointContext cxt)
    {
	// create a new list
	addPoint(cxt.getNID(),new PVector(cxt.getPtPosition().getX(),cxt.getPtPosition().getY(),cxt.getPtPosition().getZ()));

	println("OnPointCreate, handId: " + cxt.getNID());
    }

    public void OnPointUpdate(XnVHandPointContext cxt)
    {
	//println("OnPointUpdate " + cxt.getPtPosition());
	addPoint(cxt.getNID(),new PVector(cxt.getPtPosition().getX(),cxt.getPtPosition().getY(),cxt.getPtPosition().getZ()));
    }

    public void OnPointDestroy(long nID)
    {
	println("OnPointDestroy, handId: " + nID);

	// remove list
	if(_pointLists.containsKey(nID))
	    _pointLists.remove(nID);
    }

    public ArrayList getPointList(long handId)
    {
	ArrayList curList;
	if(_pointLists.containsKey(handId))
	    curList = (ArrayList)_pointLists.get(handId);
	else
	    {
		curList = new ArrayList(_maxPoints);
		_pointLists.put(handId,curList);
	    }
	return curList;
    }

    public void addPoint(long handId,PVector handPoint)
    {
	ArrayList curList = getPointList(handId);

	curList.add(0,handPoint);
	if(curList.size() > _maxPoints)
	    curList.remove(curList.size() - 1);
	_times.add(0, millis());
	if(_times.size() > _maxPoints)
	    _times.remove(_times.size() - 1);
    }

    public void draw()
    {
	if(_pointLists.size() <= 0)
	    return;

	pushStyle();
	noFill();

	PVector vec;
	PVector firstVec;
	PVector screenPos = new PVector();
	int colorIndex=0;

	// draw the hand lists
	Iterator<Map.Entry> itrList = _pointLists.entrySet().iterator();
	while(itrList.hasNext())
	    {
		strokeWeight(2);
		stroke(_colorList[colorIndex % (_colorList.length - 1)]);

		ArrayList curList = (ArrayList)itrList.next().getValue();

		// draw line
		firstVec = null;
		Iterator<PVector> itr = curList.iterator();
		float min = 0;
		float max = 0;
		boolean changed = false;
		int count = 0;
		PVector last1;
		PVector last2;
		beginShape();
		while (itr.hasNext()) {
		    vec = itr.next();
		    if(firstVec == null) {
			context.convertRealWorldToProjective(vec,screenPos);
			firstVec = vec;
		    }
		    // calc the screen pos
		    context.convertRealWorldToProjective(vec,screenPos);
		    vertex(screenPos.x,screenPos.y);
		}
		endShape();		
		// draw current pos of the hand
		if(firstVec != null) {
		    strokeWeight(8);
		    context.convertRealWorldToProjective(firstVec,screenPos);
		    if(curList.size() > 3) {			
			PVector p1 = (PVector)curList.get(1);
			PVector p2 = (PVector)curList.get(0);
			PVector p3 = (PVector)curList.get(2);
			PVector a = new PVector(p1.x - p2.x, p1.y - p2.y);
			PVector b = new PVector(p1.x - p3.x, p1.y - p3.y);
			if(degrees(PVector.angleBetween(a, b)) < 100) {
			    change.add(0, (Integer)_times.get(1));
			    if(change.size() > _maxChange) {
				change.remove(change.size() - 1);
			    }
			    if(change.size() > 1) {
				int avg = 0;
				for(int i = 0; i < change.size() - 1; ++i) {
				    avg += (Integer)change.get(i) - (Integer)change.get(i+1);
				}
				println((1000.0) / (avg / change.size()));
				//pen15.write((1000.0) / (avg / change.size()) * 15);
			    }
			}
		    }
		    point(screenPos.x,screenPos.y);
		}
		else {
		    //pen15.write(0);
		}
		colorIndex++;
	    }

	popStyle();
    }

}

