program haudorf;

{The basic type, representing both points and vectors in 2D spaces.}
type Vector = array [0..1] of Double;

{The wrapper for the Vector type, allowing to put Vectors to linked lists.}
type pNode = ^node;
	node = record
		prev, next: pNode;
		data: vector;
	end;

{An implementation of a Linked List data structure. Fields that are used in it:
	'head', 'tail' - pointers referring to the first and las elements in the list
	'size' - number of elements stored in the list
	'looped' - indicates, if the element following by the tail is the head of the list}
type pLinkedList = ^linkedList;
	linkedList = record
		head, tail: pNode;
		size: Integer;
		looped: Boolean;
	end;

var pol1, pol2, vecs: pLinkedList;

{A threshold. This value is used for imprecise comparisons.}
var ROUND_KOEF: Double = 0.0001;

{	'inFolder', 'outFolder' - the paths to the input and output folders, written with double back-slashes ('\\') as separators, ending with two backslashes.
		Example: 'D:\\Ring\\Experiments\\University\\Zlomky\\Input\\'
		Note: for the standard input a shortcut 'stdin' is used. Symmetrically, the shortcut 'stdout' is used for the standard output.
	'inF1', 'inF2' 'outF' - the names of the input and the output files.
	Example: 'input.txt'}
var inFolder, outFolder: String;
var inF1, inF2, outF: Text;

{Variables related to communication with user.
	1. 'mute' - if mute=True, then messages describing the stages of the programme's work will not be printed out. Default value is 'False'.
	2. 'inCommand' - the variable used for reading the commands entered by user.}
var mute: Boolean;
var inCommand: String;

{*Block of code with procedures related to work with lists*}

{The procedure creates a vector using the passed coordinates and wraps it into passed wrapper.
	'wrapper' - the wrapper to wrap the vector in.
	'x', 'y' - the coordinates of the vector.}
procedure wrapvector(var wrapper: pNode; x, y: Double);
	begin
		new(wrapper);

		wrapper^.prev := nil;
		wrapper^.next := nil;

		wrapper^.data[0] := x;
		wrapper^.data[1] := y;
	end;

{The procedure adds wrapped items to the specified list. The list should be initialised prior to calling the procedure.
	'target' - the list to add item to.
	'item' - the item to be added.}
procedure addNodeTo(target: pLinkedList; item: pNode);//Initialised lists only
	begin
		if target^.tail = nil then begin
			target^.head := item;
			target^.tail := item;
			target^.size := 1;
		end
		else begin
			target^.tail^.next := item;
			item^.prev := target^.tail;
			target^.tail := item;
			target^.size := target^.size + 1;
		end;
	end;

{The procedure adds a vector specified by its coordinates to the specified list. The list should be initialised prior to calling the procedure.
	'target' - the list to add item to.
	'x', 'y' - the coordinates of the vector to be added.}
procedure addTo(var target: pLinkedList; x, y: Double);
	var curNode: pNode;
	begin
		wrapvector(curNode, x, y);
		addNodeTo(target, curNode);
	end;

{The procedure adds a vector to the specified list. The list should be initialised prior to calling the procedure.
	'target' - the list to add item to.
	'p' - the vector to be added to the list.}
procedure addTo(var target: pLinkedList; p: Vector);
	begin
		addTo(target, p[0], p[1]);
	end;

{The procedure initialises the list: allocates the memory for it, sets the 'head' and 'tail' fields to 'nil', sets zero as a starting value for the 'size' field.
	'target' - the field to be initialised.}
procedure initList(var target: pLinkedList);
	begin
		new(target);
		target^.head := nil;
		target^.tail := nil;
		target^.size := 0;
		target^.looped := False;
	end;

{The procedure loops the list. It means, that it makes the head item be the next item after the tail.
	'target' - the list to be looped.}
procedure loopTheList(var target: pLinkedList);
	begin
		target^.tail^.next := target^.head;
		target^.head^.prev := target^.tail;
		target^.looped := True;
	end;

{The function provides an access to the list's elements by their index. If the list is looped, the index could exceed the list's size. The index starts from 0.
	'target' - the list to get element from.
	'n' - the index of an element.}
function get(target: pLinkedList; n: Integer): pNode;
	var i: Integer;
	var curNode: pNode;
	begin
		if (n > target^.size) and (not target^.looped) then get := nil
		else begin
			n := n mod target^.size;
			curNode := target^.head;

			for i := 1 to n do begin
				curNode := curNode^.next;
			end;

			get := curNode
		end;
	end;

{The function returns true if the specified vector is already present in the specified list.
	'target' - the list to be tested.
	'p' - the item to look for.}
function isInList(target: pLinkedList; p: Vector): Boolean;
	var i: Integer;
	var curNode: pNode;
	begin
		if (target^.head = nil) then begin
			isInList := false;
			exit;
		end;

		curNode := target^.head;

		for i:= 1 to target^.size do begin
			if ((curNode^.data[0] = p[0]) and (curNode^.data[1] = p[1])) then begin
				isInList := True;
				exit;
			end;
			curNode := curNode^.next;
		end;

		isInList := false;
	end;

{*Block of code with the Input-Output procedures*}

{The procedure prints a vector, using the parameters passed to perfrom a formatted output.
	'p' - the vector to be printed out.
	'fReal', 'fFract' - the parameters for output formatting.
	'target' - the output stream to print to.}
procedure printFormatVector(p: Vector; fReal, fFract: Integer; var target: Text);
	begin
		writeln(target, p[0]:fReal:fFract, '; ', p[1]:fReal:fFract);
	end;

{The procedure prints out the list, using the parameters passed to perfrom a formatted output.
	'list' - the list to be printed out.
	'fReal', 'fFract' - the parameters to format the output.
	'target' - the output stream to print to.}
procedure printFormatList(list: pLinkedList; fReal, fFract: Integer; var target: Text);
	var i: Integer;
	var curNode: pNode;
	begin
		curNode := list^.head;
		for i := 1 to list^.size do begin
			printFormatVector(curNode^.data, fReal, fFract, target);
			curNode := curNode^.next;
		end;
	end;

{The procedure reads the polygon from the specified input stream and writes them to the specified list. The list should be initialised prior to calling of the procedure.
	The data format is the following. The single number on the first line specifies the number of points in the polygon. Each of the following lines contains two numbers with an x- and y-coordinates of the point. The list is looped after data are read.
	'target' - the list to write the data to.
	'source' - the input stream to read from.}
procedure readPolygon(target: pLinkedList; var source: Text);
	var i, n: Integer;
	var x, y: Double;

	begin
		readln(source, n);

		for i := 1 to n do begin
			readln(source, x, y);
			addTo(target, x, y);
		end;

		loopTheList(target);
	end;

{The procedure initialises the list, reads the polygon from the specified input stream, and writes them to the specified list.
	The data format is the following. The single number on the first line specifies the number of points in the polygon. Each of the following lines contains two numbers with an x- and y-coordinates of the point. The list is looped after data are read.
	'target' - the list to write the data to.
	'source' - the input stream to read from.}
procedure initAndReadPolygon(var target: pLinkedList; var source: Text);
	begin
		initList(target);
		readPolygon(target, source);
	end;

{The procedure prepares the external resources: assigns the files on the disk to the proper variables and opens them.}
procedure prepareSources(inPath1, inPath2, outPath: String);
	begin
		if (inFolder <> 'stdin') then begin
			assign(inF1, inFolder + inPath1);
			assign(inF2, inFolder + inPath2);
			reset(inF1);
			reset(inF2);
		end
		else begin
			inF1 := Input;
			inF2 := Input;
		end;
		if (outFolder <> 'stdout') then begin
			assign(outF, outFolder + outPath);
			rewrite(outF);
		end
		else outF := Output;
	end;

{The procedure closes the external resources.}
procedure closeSources();
	begin
		if (inFolder <> 'stdin') then begin
			close(inF1);
			close(inF2);
		end;
		if (outFolder <> 'stdout') then close(outF);
	end;

{*The block of code with basic vector operations*}

{The function calculates the scalar product of the vectors.
	'a', 'b' - the vectors to be multiplied.}
function scalarProduct(a, b: Vector): Double;
	begin
		scalarProduct := (a[0] * b[0]) + (a[1] * b[1]);
	end;

{The function calculates the pseudo scalar product of two vectors.
Note: pseudo scalar product is defined as a product of vectors' lengths multiplied by the sinus of the angle between the vectors.
	'a', 'b' - the vectors to be multiplied.}
function pseudoScalarProduct(a, b: Vector): Double;
	begin
		pseudoScalarProduct := (a[0] * b[1]) - (a[1] * b[0]);
	end;

{The function calculates the vector's length.}
function vectorLength(a: Vector): Double;
	begin
		vectorLength := sqrt((a[0] * a[0]) + (a[1] * a[1]));
	end;

{The function calculates the vector sum of two vectors.}
function vectorSum(a, b: Vector): vector;
	begin
		vectorSum[0] := a[0] + b[0];
		vectorSum[1] := a[1] + b[1];
	end;

{The function calculates the vector remainder of two vectors.}
function vectorRemainder(a, b: Vector): vector;
	begin
		vectorRemainder[0] := a[0] - b[0];
		vectorRemainder[1] := a[1] - b[1];
	end;

{The function returns the normalised vector.}
function normalise(vec: Vector): vector;
	var len: Double;
	begin
		len := vectorLength(vec);
		normalise[0] := vec[0] / len;
		normalise[1] := vec[1] / len;
	end;

{the function calculates the inverted vector.}
function swap(vec: Vector): vector;
	begin
		swap[0] := -vec[0];
		swap[1] := -vec[1];
	end;

{The function multiplies the vector by the specified real number.}
function multiply(vec: Vector; n: Double): vector;
	begin
		multiply[0] := vec[0] * n;
		multiply[1] := vec[1] * n;
	end;

{*Block of code responsible for calculation of Hausdorf distances*}

{The function calculates the distance vector between a point and a section.
	'a', 'b' - the ends of the section.
	'p' - the point.}
function pointSectionDistanceVector(a, b: Vector; p: Vector): vector;
	var falls1, falls2: Boolean;
	var ab, ap, bp: Vector;
	var t: Double;
	var tAB: vector;
	begin
		ab := vectorRemainder(b, a);
		ap := vectorRemainder(p, a);
		bp := vectorRemainder(p, b);

		falls1 := scalarProduct(ab, ap) > 0;
		falls2 := scalarProduct(swap(ab), bp) > 0;

		if (not falls1) then begin
			pointSectionDistanceVector := swap(ap);
			exit;
		end;

		if (not falls2) then begin
			pointSectionDistanceVector := swap(bp);
			exit;
		end;

		t := scalarProduct(ab, ap) / scalarProduct(ab, ab);
		tAB := multiply(ab, t);
		tAB := vectorSum(a, tAB);

		pointSectionDistanceVector := vectorRemainder(tAB, p);
	end;

{The functions tests whether the point belongs to the internal area of the polygon.
Note: the method used in this procedures returns the valid answer if the polygon is convex. Otherwise it is not applicable.
	'pol' - the polygon.
	'p' - the point.}
function contains(pol: pLinkedList; p: Vector): Boolean;
	var ab, bc, ap, bp: Vector;
	var pr1, pr2: Double;
	var i: Integer;
	var curNode: pNode;
	begin
		if(pol^.size < 2) then begin
			contains := false;
			exit;
		end;

		curNode := pol^.head;
		bc := vectorRemainder(curNode^.next^.data, curNode^.data);
		bp := vectorRemainder(p, curNode^.data);
		pr2 := pseudoScalarProduct(bp, bc);
		curNode := curNode^.next;

		for i := 1 to pol^.size do begin
			ab := bc;
			bc := vectorRemainder(curNode^.next^.data, curNode^.data);
			ap := bp;
			bp := vectorRemainder(p, curNode^.data);
			pr1 := pr2;
			pr2 := pseudoScalarProduct(bp, bc);

			curNode := curNode^.next;

			if (abs(pr1) < ROUND_KOEF) and (abs(pr2) < ROUND_KOEF) then begin
				contains := True;
				exit;
			end

			else if (abs(pr1) < ROUND_KOEF) or (abs(pr2) < ROUND_KOEF) then begin
				continue;
			end;

			if (pr1 * pr2 < 0) then begin
				contains := false;
				exit;
			end;
		end;

		contains := True;
	end;

{The procedure gets the shortest vectors form the source list and puts them to the target list.
Note: the comparison is performed impreciesly, using the ROUND_KOEF threshold.}
procedure getMin(target, source: pLinkedList);
	var i: Integer;
	var min: Double;
	var curNode: pNode;

	begin
		curNode := source^.head;
		min := vectorLength(curNode^.data);
		curNode := curNode^.next;

		for i := 2 to source^.size do begin
			if (vectorLength(curNode^.data) < min) then min := vectorLength(curNode^.data);
			curNode := curNode^.next;
		end;

		curNode := source^.head;

		for i := 1 to source^.size do begin
			if abs(vectorLength(curNode^.data) - min) < ROUND_KOEF then addTo(target, curNode^.data);
			curNode := curNode^.next;
		end;
	end;

{The procedure gets the longest vectors form the source list and puts them to the target list.
Note: the comparison is performed impreciesly, using the ROUND_KOEF threshold.}
procedure getMax(target, source: pLinkedList);
	var i: Integer;
	var max: Double;
	var curNode: pNode;

	begin
		curNode := source^.head;
		max := vectorLength(curNode^.data);
		curNode := curNode^.next;

		for i := 2 to source^.size do begin
			if (vectorLength(curNode^.data) > max) then max := vectorLength(curNode^.data);
			curNode := curNode^.next;
		end;

		curNode := source^.head;

		for i := 1 to source^.size do begin
			if abs(vectorLength(curNode^.data) - max) < ROUND_KOEF then addTo(target, curNode^.data);
			curNode := curNode^.next;
		end;
	end;

{The procedure copies the source list to the target list removing the duplicates of the items in the source list.}
procedure deleteCopies(target, source: pLinkedList);
	var i: Integer;
	var curNode: pNode;
	begin
		curNode := source^.head;
		for i := 1 to source^.size do begin
			if (not isInList(target, curNode^.data)) then addTo(target, curNode^.data);
			curNode := curNode^.next;
		end;
	end;

{The procedure calculates the distance vectors from the point to the edges of the polygon. The results are stored in the specified list.}
procedure pointPolygonDistanceVectors(target, pol: pLinkedList; p: Vector);
	var i: Integer;
	var curNode: pNode;
	begin
		if (contains(pol, p)) then addTo(target, 0, 0)
		else begin
			curNode := pol^.head;
			for i := 1 to pol^.size do begin
				addTo(target, pointSectionDistanceVector(curNode^.data, curNode^.next^.data, p));
				curNode := curNode^.next;
			end;
		end;
	end;

{The procedure calculates the shortest distance vectors from each vertex of the first polygon to the second polygon. The data are stored to the specified list.}
procedure polygonPolygonDistanceVectors(target, pol1, pol2: pLinkedList); //от первого ко второму
	var i: Integer;
	var curNode: pNode;
	var pom1: pLinkedList;
	begin
		curNode := pol1^.head;

		for i := 1 to pol1^.size do begin
			initList(pom1);
			pointPolygonDistanceVectors(pom1, pol2, curNode^.data);

			getMin(target, pom1);

			curNode := curNode^.next;
		end;
	end;

{The procedure calculates the non-symmetric Hausdorff distance from the first polygon to the second one. The data are stored in the specified list.}
procedure hausdorfDistanceVectors(target, pol1, pol2: pLinkedList);//от первого ко второму
	var pom1, pom2: pLinkedList;
	var i: Integer;
	var curNode: pNode;
	begin
		initList(pom1);
		initList(pom2);
		polygonPolygonDistanceVectors(pom1, pol1, pol2);
		getMax(pom2, pom1);
		initList(pom1);
		polygonPolygonDistanceVectors(pom1, pol2, pol1);

		curNode := pom1^.head;
		for i := 1 to pom1^.size do begin
			curNode^.data := swap(curNode^.data);
			curNode := curNode^.next;
		end;
		getMax(pom2, pom1);
		initList(pom1);
		getMax(pom1, pom2);
		deleteCopies(target, pom1);
	end;

{*Block of code responsible for optimality tests*}

{The function determines the quadrant which the point belongs to. Zero is considered as point of the first quadrant. Each half-axis belongs to the quadrant to its left.}
function quadrant(p: vector): Integer;
	begin
		quadrant := 1;
		if(p[0] > 0) and (p[1] >= 0) then quadrant := 1
		else if (p[0] <= 0) and (p[1] > 0) then quadrant := 2
		else if (p[0] < 0) and (p[1] <= 0) then quadrant := 3
		else if (p[0] >= 0) and (p[1] < 0) then quadrant := 4;
	end;

{The fucntion defining the order of the vectors (based on the angle to the OX-axis).}
function compare(p1, p2: vector): Integer;
	begin
		if (quadrant(p1) > quadrant(p2)) then begin
				compare := -1;
				exit
		end
		else if (quadrant(p1) < quadrant(p2)) then begin
			compare := 1;
			exit
		end
		else begin
			p1 := normalise(p1);
			p2 := normalise(p2);

			if (quadrant(p1) = 1) or (quadrant(p1) = 2) then begin
				if (p1[0] < p2[0]) then begin
					compare := -1;
					exit;
				end
				else if (p1[0] < p2[0]) then begin
					compare := 1;
					exit;
				end
				else begin
					compare := 0;
					exit;
				end;
			end
			else begin
				if (p1[0] > p2[0]) then begin
					compare := -1;
					exit;
				end
				else if (p1[0] > p2[0]) then begin
					compare := 1;
					exit;
				end
				else begin
					compare := 0;
					exit;
				end;
			end;
		end;
	end;

{The procedure adds the vector to the specified list considering its order defined by the 'compare()' function.}
procedure addToQ(target: pLinkedList; p: vector);
	var nd, current, pom: pNode;

	begin
		{Wrap the node to the queue item container}
		new(nd);
		nd^.data := p;
		nd^.next := nil;
		nd^.prev := nil;

		if target^.head = nil then begin
			target^.head := nd;
			target^.tail := nd;
			target^.size := target^.size + 1;
		end
		{Walk along the queue until the place for the item is found. The item should be inserted before the 'current' item. We need to be careful in the situations when the 'current' item is the last one in the queue though.}
		else begin
			current := target^.head;
			while (compare(nd^.data, current^.data) = -1) and (current^.next <> nil) do begin
				current := current^.next;
			end;

			if current = target^.head then begin
				if compare(nd^.data, current^.data) = 1 then begin
					nd^.next := target^.head;
					target^.head^.prev := nd;
					target^.head := nd;
					target^.size := target^.size + 1;
				end
				else begin
					current^.next := nd;
					nd^.prev := current;
					target^.size := target^.size + 1;
				end;
			end
			else if compare(nd^.data, current^.data) = 1 then begin
				nd^.next := current;
				nd^.prev := current^.prev;
				current^.prev := nd;

				pom := nd^.prev;

				pom^.next := nd;
				target^.size := target^.size + 1;
			end
			else begin
				current^.next := nd;
				nd^.prev := current;
				target^.size := target^.size + 1;
			end;
		end;
	end;

{The procedure puts the vectors from the source list to the target list in the way, that the angle, closed to the OX-axis is non-decreasing.}
procedure sortByAngle(target, source: pLinkedList);
	var i: Integer;
	var curNode: pNode;
	begin
		curNode := source^.head;

		for i := 1 to source^.size do begin
			addToQ(target, curNode^.data);
			curNode := curNode^.next;
		end;

		target^.tail := get(target, target^.size-1);
		loopTheList(target);
	end;

{The function defines whether the current position of two convex polygons is optimal or not.}
function isOptimal(distVecs: pLinkedList): Boolean;
	var pom: pLinkedList;
	var zero: vector;
	begin
		if distVecs^.size = 1 then begin
			if vectorLength(distVecs^.head^.data) < ROUND_KOEF then begin
				isOptimal := true;
				exit
			end
			else begin
				isOptimal := false;
				exit;
			end
		end
		else if distVecs^.size = 2 then begin
			if (pseudoScalarProduct(distVecs^.head^.data, distVecs^.head^.next^.data) <= 0) and
			(abs(pseudoScalarProduct(normalise(distVecs^.head^.data), normalise(distVecs^.head^.next^.data)))<ROUND_KOEF) then begin
				isOptimal := true;
				exit;
			end
			else begin
				isOptimal := false;
				exit;
			end
		end
		else begin
			initList(pom);
			sortByAngle(pom, distVecs);
			zero[0] := 0;
			zero[1] := 0;
			isOptimal := contains(pom, zero);
		end;
	end;

{*Block of code responsible for communications with the user*}

{The simple procedure for printing out messages to the stdout stream. Messages will not be printed if 'mute = True'.}
procedure status(str: String);
	begin
		if not mute then writeln(str);
	end;

{The procedure assembles the separate procedures and subprograms to a single block of code. It reads the polygons from the defined input streams; calculates the symmetrical Hausdorff distance between them; prints the vectors, on which the Hausdorff distance is reached, to the specified output streams; tests, whether the position is optimal, or not.}
procedure process(inFile1, inFile2, outFile: String);
	begin
		status('Reading data');
		prepareSources(inFile1, inFile2, outFile);

		initAndReadPolygon(pol1, inF1);
		status('');
		initAndReadPolygon(pol2, inF2);
		writeln('');
		status('Finished reading data. Processing');
		initList(vecs);
		hausdorfDistanceVectors(vecs, pol1, pol2);
		status('Finished calculating Hausdorf vectors');
		writeln(outFile, 'Vectors');
		printFormatList(vecs, 5, 5, outF);
		writeln(outf, '');
		writeln(outF, 'Length: ',  vectorLength(vecs^.head^.data):5:5);
		writeln(outF, 'Position is optimal: ', isOptimal(vecs));
		status('Finished printing data out');
		closeSources;
		status('Process finished');
		status('***');
	end;

procedure prcs();
	var path1, path2, path3: String;
	begin
		if(inFolder <> 'stdin') then begin
				write('Enter the name of the first polygon: ');
				readln(path1);
				writeln('');
				write('Enter the name of the second polygon: ');
				readln(path2);
			end
			else writeln('Input: stdin');

			if(outFolder <> 'stdout') then begin
				write('Enter the name of the output file: ');
				readln(path3);
			end
			else writeln('Output: stdout');

			process(path1, path2, path3);
	end;

procedure printIntro();
	begin
		writeln('');
		writeln('Hausdorf v.1.0');
		writeln('');
		writeln('Charles University in Prague, Faculty of Mathematics and Physics');
		writeln('Summer semester, school year 2016/2017');
		writeln('Matvei Slavenko, Obecna matematika, the first year');
		writeln('NMIN102 Programming II');


		writeln('Use "?" or "help" to get the list of commands and their description.');
		writeln('************************************');
		writeln('');
	end;

procedure printSettings();
	begin
		writeln('Current path to the input folder is:');
		writeln(inFolder);
		writeln();
		writeln('Current path to the output folder is:');
		writeln(outFolder);
		writeln();
		write('Mute: ');
		writeln(mute);
		write('ROUND_KOEF: ');
		writeln(ROUND_KOEF);
	end;

procedure help();
	begin
		writeln('Main commands:');
		writeln('* prcs - process. The command starts processinf of the polygons.');
		writeln('* q, exit - quit. Use this command to quit the programme.');
		writeln('');

		writeln('Informative commands:');
		writeln('* sets - settings. Prints the current input and output folders, and the mute setting.');
		writeln('* credits. Prints the short information about the programme.');
		writeln('');

		writeln('Commands related to the programme settings:');
		writeln('* chgin - change input folder. Use this command to change the setting. Use "\\" as a separator. The path to the folder should finish with "\\".');
		writeln('* chgout - change output folder. Use this command to change the setting. Use "\\" as a separator. The path to the folder should finish with "\\".');
		writeln('* chgrk - change rounding threshold (rounding koefficient). Use this command to change the setting.');
		writeln('* mute. Mutes the messages related to the rendering process printed by the "prcs" command.');
		writeln('* unmute. Allows the "prcs" command to print the messages related to the rendering process.');
		writeln('');
	end;

procedure unknownCommand();
	begin
		writeln('Unknown command. Use "?" or "help" to get the list of commands and their descriptions.');
	end;

procedure changeInFolder();
	var path1: String;
	begin
		write('Enter the name of the new input folder. Use "stdin" as a shortcut for the standard input: ');
		readln(path1);
		writeln();
		inFolder := path1;
	end;

procedure changeOutFolder();
	var path1: String;
	begin
		write('Enter the name of the new output folder. Use "stdout" as a shortcut for the standard output: ');
		readln(path1);
		writeln();
		outFolder := path1;
	end;

procedure changeRoundKoef();
	var path1: Double;
	begin
		write('Enter new rounding threshold: ');
		readln(path1);
		writeln();
		ROUND_KOEF := path1;
	end;

{The procedure processes the command that was typed by user. The control is passed to the relevant procedure or subprogram. If the command is not in the list, the procedure 'unknownCommand()' will be called.
	'com' - the command to be processed.}
procedure processCommand(com: String);
	begin
		if (com = 'help') or (com = '?') then help()
		else if (com = 'prcs') then prcs()
		else if (com = 'credits') then printIntro()
		else if (com = 'sets') then printSettings()
		else if (com = 'chgin') then changeInFolder()
		else if (com = 'chgout') then changeOutFolder()
		else if (com = 'mute') then mute := True
		else if (com = 'unmute') then mute := False
		else if (com = 'chgrk') then changeRoundKoef()
		else if (com = 'q') or (com = 'exit') then com := com {Do nothing}
		else unknownCommand();
	end;

{The actual body of the programme. Sets the default values for the 'inFolder' and 'outFolder' variables, prints out the information about the programme and the current settings, launches the standard working loop of the programme.}
begin
	inFolder := 'D:\\Ring\\Experiments\\University\\Hausd\\Input\\';
	outFolder := 'D:\\Ring\\Experiments\\University\\Hausd\\Output\\';

	printIntro();
	printSettings();

	repeat
		readln(inCommand);
		processCommand(inCommand)
	until (inCommand = 'q') or (inCommand = 'exit');
end.