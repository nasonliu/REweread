import fs from 'node:fs';

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const qml = fs.readFileSync('apps/weread-qt/ShelfPage.qml', 'utf8');
const gridStart = qml.indexOf('id: shelfGrid');
const gridEnd = qml.indexOf('id: emptyShelfState', gridStart);
const grid = qml.slice(gridStart, gridEnd);

assert(gridStart >= 0 && gridEnd > gridStart, 'shelf grid must exist');
assert(grid.includes('id: shelfPageSwipeHandler'), 'shelf grid must have a dedicated swipe handler');
assert(grid.includes('acceptedDevices: PointerDevice.TouchScreen | PointerDevice.Mouse'), 'shelf swipe must accept the Move touch device even when Qt exposes it as a mouse pointer');
assert(grid.includes('grabPermissions: PointerHandler.CanTakeOverFromAnything'), 'shelf swipe must take over after a cover press becomes a horizontal drag');
assert(grid.includes('target: null'), 'shelf swipe must detect gestures without moving the grid');
assert(grid.includes('Math.abs(dx) < 92'), 'shelf swipe must require an intentional horizontal distance');
assert(grid.includes('Math.abs(dx) < Math.abs(dy) * 1.35'), 'shelf swipe must reject mostly vertical gestures');
assert(grid.includes('dx < 0') && grid.includes('appRoot.goShelfPage(1)'), 'left swipe must show the next shelf page');
assert(grid.includes('dx > 0') && grid.includes('appRoot.goShelfPage(-1)'), 'right swipe must show the previous shelf page');
assert(grid.includes('TapHandler {') && grid.includes('gesturePolicy: TapHandler.ReleaseWithinBounds'), 'cover opening must use a tap handler that yields to shelf drags');
assert(!grid.includes('MouseArea {\n\t\t                        anchors.fill: parent'), 'cover delegates must not monopolize touch with the old mouse area');
assert(!grid.includes('NumberAnimation') && !grid.includes('PropertyAnimation'), 'shelf page changes must not animate on e-ink');

console.log('shelf swipe ok');
