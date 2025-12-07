import { test } from "node:test";
import assert from "node:assert";
import {
  isValidLatitude,
  isValidLongitude,
  parseCoordinates,
  isInBCArea,
} from "../src/helpers/coordinates.js";

test("isValidLatitude", async (t) => {
  await t.test("returns true for valid latitude values", () => {
    assert.strictEqual(isValidLatitude(0), true);
    assert.strictEqual(isValidLatitude(45), true);
    assert.strictEqual(isValidLatitude(-45), true);
    assert.strictEqual(isValidLatitude(90), true);
    assert.strictEqual(isValidLatitude(-90), true);
    assert.strictEqual(isValidLatitude(49.2827), true);
  });

  await t.test("returns false for invalid latitude values", () => {
    assert.strictEqual(isValidLatitude(91), false);
    assert.strictEqual(isValidLatitude(-91), false);
    assert.strictEqual(isValidLatitude(NaN), false);
    assert.strictEqual(isValidLatitude(Infinity), false);
    assert.strictEqual(isValidLatitude(-Infinity), false);
    assert.strictEqual(isValidLatitude("45"), false);
    assert.strictEqual(isValidLatitude(null), false);
    assert.strictEqual(isValidLatitude(undefined), false);
  });
});

test("isValidLongitude", async (t) => {
  await t.test("returns true for valid longitude values", () => {
    assert.strictEqual(isValidLongitude(0), true);
    assert.strictEqual(isValidLongitude(45), true);
    assert.strictEqual(isValidLongitude(-45), true);
    assert.strictEqual(isValidLongitude(180), true);
    assert.strictEqual(isValidLongitude(-180), true);
    assert.strictEqual(isValidLongitude(-123.1207), true);
  });

  await t.test("returns false for invalid longitude values", () => {
    assert.strictEqual(isValidLongitude(181), false);
    assert.strictEqual(isValidLongitude(-181), false);
    assert.strictEqual(isValidLongitude(NaN), false);
    assert.strictEqual(isValidLongitude(Infinity), false);
    assert.strictEqual(isValidLongitude(-Infinity), false);
    assert.strictEqual(isValidLongitude("45"), false);
    assert.strictEqual(isValidLongitude(null), false);
    assert.strictEqual(isValidLongitude(undefined), false);
  });
});

test("parseCoordinates", async (t) => {
  await t.test("parses valid coordinate strings", () => {
    const result = parseCoordinates("49.2827", "-123.1207");
    assert.deepStrictEqual(result, { lat: 49.2827, lon: -123.1207 });
  });

  await t.test("parses integer coordinate strings", () => {
    const result = parseCoordinates("45", "-120");
    assert.deepStrictEqual(result, { lat: 45, lon: -120 });
  });

  await t.test("returns null for invalid latitude", () => {
    assert.strictEqual(parseCoordinates("91", "-120"), null);
    assert.strictEqual(parseCoordinates("-91", "-120"), null);
  });

  await t.test("returns null for invalid longitude", () => {
    assert.strictEqual(parseCoordinates("45", "181"), null);
    assert.strictEqual(parseCoordinates("45", "-181"), null);
  });

  await t.test("returns null for non-numeric strings", () => {
    assert.strictEqual(parseCoordinates("abc", "-123"), null);
    assert.strictEqual(parseCoordinates("45", "xyz"), null);
  });

  await t.test("returns null for missing parameters", () => {
    assert.strictEqual(parseCoordinates("", "-123"), null);
    assert.strictEqual(parseCoordinates("45", ""), null);
    assert.strictEqual(parseCoordinates(null, "-123"), null);
    assert.strictEqual(parseCoordinates("45", null), null);
    assert.strictEqual(parseCoordinates(undefined, undefined), null);
  });

  await t.test("handles NaN strings", () => {
    assert.strictEqual(parseCoordinates("NaN", "-123"), null);
    assert.strictEqual(parseCoordinates("45", "NaN"), null);
  });
});

test("isInBCArea", async (t) => {
  await t.test("returns true for coordinates within BC bounds", () => {
    // Vancouver area
    assert.strictEqual(isInBCArea(49.2827, -123.1207), true);
    // Victoria area
    assert.strictEqual(isInBCArea(48.4284, -123.3656), true);
    // Kelowna area
    assert.strictEqual(isInBCArea(49.7917, -119.4944), true);
  });

  await t.test("returns true for boundary coordinates", () => {
    assert.strictEqual(isInBCArea(48.3, -139.0), true);
    assert.strictEqual(isInBCArea(60.0, -114.0), true);
  });

  await t.test("returns false for coordinates outside BC bounds", () => {
    // Too far south
    assert.strictEqual(isInBCArea(48.0, -120), false);
    // Too far north
    assert.strictEqual(isInBCArea(61.0, -120), false);
    // Too far west
    assert.strictEqual(isInBCArea(50, -140), false);
    // Too far east
    assert.strictEqual(isInBCArea(50, -113), false);
    // US coordinates (Seattle area)
    assert.strictEqual(isInBCArea(47.6, -122.3), false);
  });

  await t.test("returns false for invalid coordinate types", () => {
    assert.strictEqual(isInBCArea("49", "-123"), false);
    assert.strictEqual(isInBCArea(null, -123), false);
    assert.strictEqual(isInBCArea(49, undefined), false);
    assert.strictEqual(isInBCArea(NaN, -123), false);
  });
});
