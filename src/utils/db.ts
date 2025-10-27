import sql from 'mssql';
import dotenv from 'dotenv';
import assert from 'assert';

dotenv.config();

const {
    DB_SERVER,
    DB_USER,
    DB_PASS,
    DB_NAME,
    PORT
} = process.env; // Destructure environment variables

// Ensure all required environment variables are defined
assert(PORT, "PORT is required");
assert(DB_SERVER, "DB_SERVER is required");
assert(DB_USER, "DB_USER is required");
assert(DB_PASS, "DB_PASS is required");
assert(DB_NAME, "DB_NAME is required");

export const config = {
    port: PORT,
    sqlConfig: {
        user: DB_USER,
        password: DB_PASS,
        database: DB_NAME,
        server: DB_SERVER,
        pool: { //pool is used to manage multiple connections to the database
            max: 10,
            min: 0,
            idleTimeoutMillis: 30000
        },
        options: {
            encrypt: true, // for azure
            trustServerCertificate: true // Change to true for local dev / self-signed certs
        }
    }
};

// Create a connection pool - a cache of database connections maintained so that the connections can be reused when future requests to the database are required.
export const getDbPool = async () => {
    try {
        const pool = await sql.connect(config.sqlConfig);
        return pool;
    } catch (error) {
        console.log("SQL Connection Error: ", error);
        throw error;
    }
};




