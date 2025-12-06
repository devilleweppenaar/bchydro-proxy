export default {
  async fetch(request) {
    // Add CORS headers for Shortcuts
    const corsHeaders = {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type",
    };

    // Handle OPTIONS request for CORS
    if (request.method === "OPTIONS") {
      return new Response(null, { headers: corsHeaders });
    }

    try {
      // Fetch from BC Hydro
      const response = await fetch(
        "https://www.bchydro.com/power-outages/app/outages-map-data.json",
      );

      // Get the full response as text first (handles chunked encoding)
      const data = await response.text();

      // Return with proper headers and NO chunked encoding
      return new Response(data, {
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
          "Content-Length": data.length.toString(), // Explicit length prevents chunking
          "Cache-Control": "max-age=60", // Cache for 1 minute
        },
      });
    } catch (error) {
      return new Response(JSON.stringify({ error: error.message }), {
        status: 500,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
        },
      });
    }
  },
};
