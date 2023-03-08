exports.handler = async (event) => {
  const response = {
    statusCode: 200,
    body: JSON.stringify('Hello, world!!! Welcome to Lambda World'),
  };
  return response;
};
