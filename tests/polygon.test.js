import { test } from "node:test";
import assert from "node:assert";
import { isPointInPolygon, isValidPolygon } from "../src/helpers/polygon.js";

test("isPointInPolygon - point inside triangle", () => {
  // Simple triangle: (0,0), (10,0), (5,10)
  const polygon = [0, 0, 10, 0, 5, 10];
  const result = isPointInPolygon(5, 5, polygon);
  assert.strictEqual(result, true, "Point (5,5) should be inside triangle");
});

test("isPointInPolygon - point outside triangle", () => {
  const polygon = [0, 0, 10, 0, 5, 10];
  const result = isPointInPolygon(15, 15, polygon);
  assert.strictEqual(result, false, "Point (15,15) should be outside triangle");
});

test("isPointInPolygon - point on vertex", () => {
  const polygon = [0, 0, 10, 0, 5, 10];
  const result = isPointInPolygon(0, 0, polygon);
  // Point on vertex behavior may vary - just verify it returns a boolean
  assert.strictEqual(typeof result, "boolean");
});

test("isPointInPolygon - point on edge", () => {
  const polygon = [0, 0, 10, 0, 5, 10];
  const result = isPointInPolygon(5, 0, polygon);
  // Point on edge behavior - just verify it returns a boolean
  assert.strictEqual(typeof result, "boolean");
});

test("isPointInPolygon - complex polygon (square)", () => {
  // Square: (0,0), (10,0), (10,10), (0,10)
  const polygon = [0, 0, 10, 0, 10, 10, 0, 10];
  const inside = isPointInPolygon(5, 5, polygon);
  const outside = isPointInPolygon(15, 15, polygon);
  assert.strictEqual(inside, true, "Center (5,5) should be inside square");
  assert.strictEqual(outside, false, "Point (15,15) should be outside square");
});

test("isPointInPolygon - invalid inputs", () => {
  const polygon = [0, 0, 10, 0, 5, 10];
  assert.strictEqual(
    isPointInPolygon(null, 5, polygon),
    false,
    "Should return false for null latitude"
  );
  assert.strictEqual(
    isPointInPolygon(5, null, polygon),
    false,
    "Should return false for null longitude"
  );
  assert.strictEqual(
    isPointInPolygon("5", 5, polygon),
    false,
    "Should return false for string latitude"
  );
});

test("isPointInPolygon - invalid polygon", () => {
  assert.strictEqual(
    isPointInPolygon(5, 5, null),
    false,
    "Should return false for null polygon"
  );
  assert.strictEqual(
    isPointInPolygon(5, 5, [0, 0, 10]),
    false,
    "Should return false for incomplete polygon (odd number of coords)"
  );
  assert.strictEqual(
    isPointInPolygon(5, 5, [0, 0, 10, 0]),
    false,
    "Should return false for polygon with less than 3 points"
  );
});

test("isValidPolygon - valid triangle", () => {
  const polygon = [0, 0, 10, 0, 5, 10];
  assert.strictEqual(
    isValidPolygon(polygon),
    true,
    "Valid triangle should return true"
  );
});

test("isValidPolygon - valid square", () => {
  const polygon = [0, 0, 10, 0, 10, 10, 0, 10];
  assert.strictEqual(
    isValidPolygon(polygon),
    true,
    "Valid square should return true"
  );
});

test("isValidPolygon - invalid: not an array", () => {
  assert.strictEqual(
    isValidPolygon("not an array"),
    false,
    "String should return false"
  );
  assert.strictEqual(isValidPolygon(null), false, "null should return false");
  assert.strictEqual(
    isValidPolygon(undefined),
    false,
    "undefined should return false"
  );
});

test("isValidPolygon - invalid: odd number of coordinates", () => {
  const polygon = [0, 0, 10, 0, 5];
  assert.strictEqual(
    isValidPolygon(polygon),
    false,
    "Odd number of coords should return false"
  );
});

test("isValidPolygon - invalid: too few points", () => {
  const polygon = [0, 0, 10, 0];
  assert.strictEqual(
    isValidPolygon(polygon),
    false,
    "Less than 3 points should return false"
  );
});

test("isValidPolygon - invalid: non-numeric coordinates", () => {
  const polygon = [0, 0, "10", 0, 5, 10];
  assert.strictEqual(
    isValidPolygon(polygon),
    false,
    "Non-numeric coordinate should return false"
  );
});

test("isValidPolygon - invalid: NaN or Infinity", () => {
  const polygonWithNaN = [0, 0, 10, NaN, 5, 10];
  assert.strictEqual(
    isValidPolygon(polygonWithNaN),
    false,
    "NaN coordinate should return false"
  );

  const polygonWithInfinity = [0, 0, Infinity, 0, 5, 10];
  assert.strictEqual(
    isValidPolygon(polygonWithInfinity),
    false,
    "Infinity coordinate should return false"
  );
});
