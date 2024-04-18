#!/opt/homebrew/bin/python3.10

import argparse
import duckdb


def dump_schema(database_path, output_file):
    # Connect to the DuckDB database
    con = duckdb.connect(database_path)

    # Execute the .schema command and capture the output
    schema = con.execute(".schema").fetchall()

    # Write the schema to the output file
    with open(output_file, "w") as file:
        for table_schema in schema:
            file.write(table_schema[0] + "\n\n")

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
