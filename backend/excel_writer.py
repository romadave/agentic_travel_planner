import pandas as pd
import os

def create_data_frame(information):
    return pd.DataFrame(information)

def get_output_file(trip_request):
    output_file = f"reports/Trip_{trip_request['origin']}_to_{trip_request['destination']}_{trip_request['departure_date']}.xlsx"
    
    if os.path.exists(output_file):
        print(f"Updating existing workbook: {output_file}")
    else:
        print(f"Creating new workbook: {output_file}")
    
    return output_file


def add_multiple_sheets_to_excel(trip_request, sheets_data):
    output_file = get_output_file(trip_request=trip_request)

    with pd.ExcelWriter(output_file, engine="openpyxl") as writer:
        for sheet_name, data_frame in sheets_data.items():
            data_frame.to_excel(writer, sheet_name=sheet_name, index=False)

    return output_file