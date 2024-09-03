#!/opt/homebrew/bin/python3.10

import argparse
import duckdb

def dump_schema(database_path, output_file):
    # Connect to the DuckDB database
    con = duckdb.connect(database_path)

    # Query to get all table names
    tables = con.execute("SELECT table_name FROM information_schema.tables WHERE table_schema = 'main'").fetchall()

    # Write the schema to the output file
    with open(output_file, "w") as file:
        for table in tables:
            table_name = table[0]
            # Get the CREATE TABLE statement for each table
            create_table_stmt = con.execute(f"SELECT sql FROM sqlite_master WHERE type='table' AND name='{table_name}'").fetchone()[0]
            file.write(f"-- Table: {table_name}\n")
            file.write(f"{create_table_stmt};\n\n")

    # Close the database connection
    con.close()

    print(f"Schema dumped to {output_file}")

if __name__ == "__main__":
    # Create an argument parser
    parser = argparse.ArgumentParser(description="Dump DuckDB schema to a file")
    parser.add_argument("database", help="Path to the DuckDB database file")
    parser.add_argument("output", help="Path to the output file")

    # Parse the command-line arguments
    args = parser.parse_args()

    # Call the dump_schema function with the provided arguments
    dump_schema(args.database, args.output)
