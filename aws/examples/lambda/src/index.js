exports.handler = async (event) => {
  console.log("Event received:", JSON.stringify(event, null, 2));

  const name = event.name || "Floci";

  return {
    statusCode: 200,
    body: JSON.stringify({
      message: `Hello, ${name}! Lambda is running on Floci.`,
      timestamp: new Date().toISOString(),
    }),
  };
};
