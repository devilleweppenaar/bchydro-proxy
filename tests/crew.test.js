import { test } from "node:test";
import assert from "node:assert";
import { getCrewStatusDetail } from "../src/helpers/crew.js";

test("getCrewStatusDetail", async (t) => {
  await t.test("returns correct detail for NOT_ASSIGNED status", () => {
    const detail = getCrewStatusDetail("NOT_ASSIGNED");
    assert.ok(detail, "Should return a value for NOT_ASSIGNED");
    assert.match(detail, /crew hasn't been assigned/i);
  });

  await t.test("returns correct detail for ASSIGNED status", () => {
    const detail = getCrewStatusDetail("ASSIGNED");
    assert.ok(detail, "Should return a value for ASSIGNED");
    assert.match(detail, /crew has been assigned/i);
  });

  await t.test("returns correct detail for ENROUTE status", () => {
    const detail = getCrewStatusDetail("ENROUTE");
    assert.ok(detail, "Should return a value for ENROUTE");
    assert.match(detail, /on their way/i);
  });

  await t.test("returns correct detail for ONSITE status", () => {
    const detail = getCrewStatusDetail("ONSITE");
    assert.ok(detail, "Should return a value for ONSITE");
    assert.match(detail, /working to investigate/i);
  });

  await t.test("returns correct detail for SUSPENDED status", () => {
    const detail = getCrewStatusDetail("SUSPENDED");
    assert.ok(detail, "Should return a value for SUSPENDED");
    assert.match(detail, /equipment/i);
  });

  await t.test("returns null for unknown status", () => {
    const detail = getCrewStatusDetail("UNKNOWN_STATUS");
    assert.strictEqual(detail, null, "Should return null for unknown status");
  });

  await t.test("returns null for empty string", () => {
    const detail = getCrewStatusDetail("");
    assert.strictEqual(detail, null, "Should return null for empty string");
  });

  await t.test("returns null for null input", () => {
    const detail = getCrewStatusDetail(null);
    assert.strictEqual(detail, null, "Should return null for null input");
  });

  await t.test("returns null for undefined input", () => {
    const detail = getCrewStatusDetail(undefined);
    assert.strictEqual(detail, null, "Should return null for undefined input");
  });

  await t.test("is case-sensitive", () => {
    const detail = getCrewStatusDetail("assigned");
    assert.strictEqual(detail, null, "Should be case-sensitive");
  });

  await t.test("handles all known status codes", () => {
    const statuses = [
      "NOT_ASSIGNED",
      "ASSIGNED",
      "ENROUTE",
      "ONSITE",
      "SUSPENDED",
    ];
    statuses.forEach((status) => {
      const detail = getCrewStatusDetail(status);
      assert.ok(detail, `Should have detail for ${status}`);
      assert.strictEqual(
        typeof detail,
        "string",
        `Detail for ${status} should be string`,
      );
      assert.ok(detail.length > 0, `Detail for ${status} should not be empty`);
    });
  });
});
