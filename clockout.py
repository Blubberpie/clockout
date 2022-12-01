import argparse
import asyncio
import json
import os
from typing import Dict, Any

import hvac
from dotenv import load_dotenv
from playwright.async_api import async_playwright, Page


class Clockout:
    durations = ["1 Day", "Half Day", "2 Hours"]

    def __init__(self, args: argparse.Namespace):
        email, password = self.get_credentials()
        self.email: str = email
        self.password: str = password
        self.work: str = args.work
        self.project: str = args.project
        self.duration: str = self.durations[args.duration]
        self.shall_submit: bool = args.submit
        self.browser: bool = args.browser

    @classmethod
    def get_credentials(cls):
        with open(file=os.getenv("SECRETS_PATH"), mode="r") as f:
            secrets: Dict[str, Any] = json.load(f)
            client = hvac.Client(
                url=secrets["url"],
                token=secrets["token"]
            )
            client.sys.submit_unseal_key(secrets["k1"])
            read_response_data = client.read(os.getenv("VAULT"))["data"]
        return read_response_data["email"], read_response_data["password"]

    async def login(self, page: Page):
        await page.goto(url=os.getenv("MAIN_URL"))
        await page.wait_for_url(url=os.getenv("MAIN_URL_LOGIN"))
        await page.get_by_role(role="button", name="Login with Microsoft").click()
        await page.fill(selector="input[type='email']", value=self.email)
        await page.locator(selector="[type='submit']").click()
        await page.fill(selector="input[type='password']", value=self.password)
        await page.locator(selector="[type='submit']").click()
        if page.locator(selector="text=Stay signed in?"):
            await page.locator(selector="[type='submit']").click()

    async def clockout(self, page: Page):
        await page.get_by_label("Describe your work").fill(self.work)
        await page.get_by_role("button", name="Project").click()
        await page.get_by_role("option", name=self.project).click()
        await page.get_by_role("button", name="Duration").click()
        await page.get_by_role("option", name=self.duration).click()
        if self.shall_submit:
            expected_response_url = os.getenv("RESPONSE_URL")
            async with page.expect_response(url_or_predicate=expected_response_url):
                await page.get_by_role("button", name="Log your timesheet").click()

    async def run(self):
        async with async_playwright() as p:
            browser_type = p.firefox
            browser = await browser_type.launch(headless=not self.browser)
            page = await browser.new_page()

            await self.login(page=page)
            await self.clockout(page=page)

            await browser.close()


async def main():
    parser = argparse.ArgumentParser(prog="Clockout")
    parser.add_argument("-w", "--work", type=str, required=True, help="Work description")
    parser.add_argument("-p", "--project", type=str, required=False, default="MITONE Database", help="Project name")
    parser.add_argument(
        "-d",
        "--duration",
        type=int,
        required=False,
        default=0,
        help="Duration of work. 0=1 Day, 1=Half Day, 2=2 Hours"
    )
    parser.add_argument("-s", "--submit", action=argparse.BooleanOptionalAction, help="Shall submit")
    parser.add_argument("-b", "--browser", action=argparse.BooleanOptionalAction, help="Launch in headed mode")
    args = parser.parse_args()

    load_dotenv()

    clockout = Clockout(args)
    await clockout.run()


if __name__ == "__main__":
    asyncio.run(main())
