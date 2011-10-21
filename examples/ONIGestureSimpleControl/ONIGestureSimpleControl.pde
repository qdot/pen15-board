import SimpleOpenNI.*;
import processing.serial.*;
Serial pen15;

SimpleOpenNI      context;

// NITE
XnVSessionManager sessionManager;
XnVFlowRouter     flowRouter;

PointDrawer       pointDrawer;

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
    String f = selectInput();
	if(f == null) {
		println("No file selected, exiting");
		exit();
		return;
	}
	if( context.openFileRecording(f) == false) {
		println("can't find recording !!!!");
		exit();
		return;
	}

    println("opening file");

	initializePen15();
	context.enableScene();
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
	color[]    _colorList = { color(255,0,0),color(0,255,0),color(0,0,255),color(255,255,0)};

	public PointDrawer()
	{
		_maxPoints = 30;
		_pointLists = new HashMap();
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

				beginShape();
				while (itr.hasNext())
					{
						vec = itr.next();
						if(firstVec == null) {
							context.convertRealWorldToProjective(vec,screenPos);
							min = screenPos.y;
							max = screenPos.y;
							firstVec = vec;
						}
						// calc the screen pos
						context.convertRealWorldToProjective(vec,screenPos);
						if(min > screenPos.y)
							min = screenPos.y;
						if(max < screenPos.y)
							max = screenPos.y;
						vertex(screenPos.x,screenPos.y);
					}
				endShape();
				// draw current pos of the hand
				if(firstVec != null)
					{

						strokeWeight(8);
						context.convertRealWorldToProjective(firstVec,screenPos);
						float val = (max - screenPos.y) / (max - min);
						pen15.write((int)(255.0 * val));
						point(screenPos.x,screenPos.y);
					}
				else
					{
						pen15.write(0);
					}
				colorIndex++;
			}

		popStyle();
	}

}

