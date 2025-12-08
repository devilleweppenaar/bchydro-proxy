import { test } from "node:test";
import assert from "node:assert";
import { getTestMode, getTestOutages } from "../src/helpers/test-mode.js";

test("getTestMode", async (t) => {
  await t.test("returns null when TEST_MODE is not enabled", () => {
    const env = { TEST_MODE: "false" };
    assert.strictEqual(getTestMode(env, "outage"), null);
    assert.strictEqual(getTestMode(env, "no-outage"), null);
    assert.strictEqual(getTestMode(env, "multiple"), null);
  });

  await t.test("returns null when TEST_MODE is not set", () => {
    const env = {};
    assert.strictEqual(getTestMode(env, "outage"), null);
  });

  await t.test(
    "returns test mode when TEST_MODE is enabled and param is valid",
    () => {
      const env = { TEST_MODE: "true" };
      assert.strictEqual(getTestMode(env, "outage"), "outage");
      assert.strictEqual(getTestMode(env, "no-outage"), "no-outage");
      assert.strictEqual(getTestMode(env, "multiple"), "multiple");
    },
  );

  await t.test("returns null for invalid test mode parameter", () => {
    const env = { TEST_MODE: "true" };
    assert.strictEqual(getTestMode(env, "invalid"), null);
    assert.strictEqual(getTestMode(env, ""), null);
    assert.strictEqual(getTestMode(env, null), null);
    assert.strictEqual(getTestMode(env, undefined), null);
  });
});

test("getTestOutages", async (t) => {
  await t.test("returns outage affecting Vancouver for 'outage' mode", () => {
    const outages = getTestOutages("outage");
    assert.strictEqual(outages.length, 1);
    assert.strictEqual(outages[0].id, "test-outage-001");
    assert.strictEqual(outages[0].municipality, "Vancouver");
    assert.strictEqual(outages[0].area, "Downtown");
    assert.ok(outages[0].polygon.length > 0);
  });

  await t.test("returns Victoria outage for 'no-outage' mode", () => {
    const outages = getTestOutages("no-outage");
    assert.strictEqual(outages.length, 1);
    assert.strictEqual(outages[0].id, "test-outage-002");
    assert.strictEqual(outages[0].municipality, "Victoria");
    assert.ok(outages[0].polygon.length > 0);
  });

  await t.test("returns multiple outages for 'multiple' mode", () => {
    const outages = getTestOutages("multiple");
    assert.strictEqual(outages.length, 3);
    assert.strictEqual(outages[0].id, "test-outage-003");
    assert.strictEqual(outages[1].id, "test-outage-004");
    assert.strictEqual(outages[2].id, "test-outage-005");

    // Check that we have different municipalities
    const municipalities = outages.map((o) => o.municipality);
    assert.ok(municipalities.includes("Vancouver"));
    assert.ok(municipalities.includes("Kelowna"));
  });

  await t.test("returns empty array for invalid mode", () => {
    assert.deepStrictEqual(getTestOutages("invalid"), []);
    assert.deepStrictEqual(getTestOutages(""), []);
    assert.deepStrictEqual(getTestOutages(null), []);
    assert.deepStrictEqual(getTestOutages(undefined), []);
  });

  await t.test("all outages have required fields", () => {
    const modes = ["outage", "no-outage", "multiple"];
    modes.forEach((mode) => {
      const outages = getTestOutages(mode);
      outages.forEach((outage) => {
        assert.ok(outage.id, "Missing id");
        assert.ok(outage.municipality, "Missing municipality");
        assert.ok(outage.area, "Missing area");
        assert.ok(outage.cause, "Missing cause");
        assert.ok(
          typeof outage.numCustomersOut === "number",
          "Invalid numCustomersOut",
        );
        assert.ok(outage.crewStatus, "Missing crewStatus");
        assert.ok(
          outage.crewStatusDescription,
          "Missing crewStatusDescription",
        );
        assert.ok(typeof outage.dateOff === "number", "Invalid dateOff");
        assert.ok(
          typeof outage.lastUpdated === "number",
          "Invalid lastUpdated",
        );
        assert.ok(outage.regionName, "Missing regionName");
        assert.ok(typeof outage.showEtr === "boolean", "Invalid showEtr");
        assert.ok(typeof outage.latitude === "number", "Invalid latitude");
        assert.ok(typeof outage.longitude === "number", "Invalid longitude");
        assert.ok(Array.isArray(outage.polygon), "Invalid polygon");
        assert.ok(outage.polygon.length >= 6, "Polygon too small");
      });
    });
  });

  await t.test("test data causes are labeled with (TEST DATA)", () => {
    const modes = ["outage", "no-outage", "multiple"];
    modes.forEach((mode) => {
      const outages = getTestOutages(mode);
      outages.forEach((outage) => {
        assert.ok(
          outage.cause.includes("(TEST DATA)"),
          `Cause should include (TEST DATA): ${outage.cause}`,
        );
      });
    });
  });
});
