import asyncio
import os
import smtplib
import ssl
from email.mime.application import MIMEApplication
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText


async def send_itinerary_email(
    to_email: str,
    excel_bytes: bytes,
    pdf_bytes: bytes,
    destination: str,
) -> None:
    await asyncio.to_thread(_send_sync, to_email, excel_bytes, pdf_bytes, destination)


def _send_sync(to_email: str, excel_bytes: bytes, pdf_bytes: bytes, destination: str) -> None:
    sender = os.getenv("EMAIL_ADDRESS")
    password = os.getenv("EMAIL_APP_PASSWORD")

    if not sender or not password:
        raise ValueError("EMAIL_ADDRESS and EMAIL_APP_PASSWORD must be set in .env")

    msg = MIMEMultipart()
    msg["From"] = sender
    msg["To"] = to_email
    msg["Subject"] = f"Your {destination} Trip Itinerary"

    body = (
        f"Hi! Here's your travel itinerary for {destination}.\n\n"
        "Attached you'll find:\n"
        "  • PDF — easy to view and share\n"
        "  • Excel — editable spreadsheet with your itinerary, flights, and hotels\n\n"
        "Have a great trip!"
    )
    msg.attach(MIMEText(body, "plain"))

    filename_base = destination.replace(" ", "_")

    pdf_part = MIMEApplication(pdf_bytes, _subtype="pdf")
    pdf_part.add_header("Content-Disposition", "attachment", filename=f"{filename_base}_itinerary.pdf")
    msg.attach(pdf_part)

    xlsx_part = MIMEApplication(
        excel_bytes,
        _subtype="vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    )
    xlsx_part.add_header("Content-Disposition", "attachment", filename=f"{filename_base}_itinerary.xlsx")
    msg.attach(xlsx_part)

    context = ssl.create_default_context()
    with smtplib.SMTP("smtp.gmail.com", 587) as server:
        server.starttls(context=context)
        server.login(sender, password)
        server.sendmail(sender, to_email, msg.as_string())
