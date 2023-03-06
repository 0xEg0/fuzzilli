if (typeof output === 'undefined') output = console.log;

let counter = 5;
function countdown() {
  return counter--;
}
function resetCounter() {
  counter = 5;
}

//
// While loops
//
while (countdown()) {
  output("inside while loop body");
}
resetCounter()

while (output("inside while loop header"), output("still inside while loop header"), countdown()) {
  output("inside while loop body");
}
resetCounter();

while (output("inside while loop header"), counter) {
  output("inside while loop body");
  countdown();
}
resetCounter();

while ((function() { let c = countdown(); output("inside temporary function, c = " + c); return c; })()) {
  output("inside while loop body");
}
resetCounter();

//
// Do-While loops
//
do {
  output("inside do-while loop body");
} while (countdown())
resetCounter()

do {
  output("inside do-while loop body");
} while (output("inside do-while loop header"), output("still inside do-while loop header"), countdown())
resetCounter();

do {
  output("inside do-while loop body");
  countdown();
} while (output("inside do-while loop header"), counter)
resetCounter();

do {
  output("inside do-while loop body");
} while ((function() { let c = countdown(); output("inside temporary function, c = " + c); return c; })())
resetCounter();


/*
for (;;) {
  if (!counter--) {
    break;
  }
  output("inside for loop body");
}
resetCounter();
*/
