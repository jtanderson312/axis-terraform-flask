const dev = {
    API_URL: "localhost:5000"
};

const prod = {
    API_URL: "example.com"
};


const config = process.env.NODE_ENV === 'production' ? prod : dev;

export default {
    // Common

    // 
    ...config
}