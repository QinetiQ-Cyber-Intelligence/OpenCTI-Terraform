"""
This python script automates the process of creating a user account in OpenCTI
and prints the token for the user account in JSON format. This is needed
to automate the creation of user accounts for connectors.
"""

import requests
import json
import sys


class OpenCTIAccountHelper:
    """
    Helper class for creating accounts in OpenCTI.
    """
    def __init__(self, opencti_url, email, password):
        """
        opencti_url: a str representing the public OpenCTI URL
        email: a str representing the email to use for logging in
        password: a str representing the password to use for logging in
        """

        self._api_url = f'{opencti_url}/graphql'
        self._session = requests.Session() 
        self._login_to_opencti(
            email=email,
            password=password
        )

    def _login_to_opencti(self, email, password):
        """
        Login to OpenCTI and return a session that can be used for subsequent requests.

        email: a str representing the email to use for logging in
        password: a str representing the password to use for logging in

        return: a dict in the form:
            {"data": {"token": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"}}
        """

        post_data = {
            "id": "LoginFormMutation",
            "query": "mutation LoginFormMutation($input: UserLoginInput!) {token(input: $input)}",
            "variables": {
                "input": {
                    "email": email,
                    "password": password
                }
            }
        }

        resp = self._session.post(self._api_url, json=post_data)
        resp.raise_for_status()
        return resp.json()

    def create_user_account(self, email, password, name, first_name, last_name, description=None):
        """
        Create a user account for OpenCTI.

        email: a str representing the email for the account
        password: a str representing the password for the account
        name: a str representing the name of the account
        first_name: a str representing the first name of the account
        last_name: a str representing the last name of the account
        description: (optional) a str containing a description of the account

        returns: a dict in the form:
            {
                "data": {
                    "userAdd": {
                        "id":"34a28402-5d0f-4742-b1e0-4bfbf323f6a0",
                        "name":"ExampleName",
                        "user_email":"example@email.com",
                        "firstname":"ExampleFirstName",
                        "external":false,
                        "lastname":"ExampleLastName",
                        "otp_activated":null,
                        "created_at":"2022-08-25T02:36:08.539Z"
                    }
                }
            }
        """

        post_data = {
            "id": "UserCreationMutation",
            "query": "mutation UserCreationMutation($input: UserAddInput!) {userAdd(input: $input) {...UserLine_node  id}}fragment UserLine_node on User {id name user_email firstname external lastname otp_activated created_at}",
            "variables": {
                "input": {
                    "name": name,
                    "user_email": email,
                    "firstname": first_name,
                    "lastname": last_name,
                    "password": password
                }
            }
        }

        if description:
            post_data['variables']['input']['description'] = description

        resp = self._session.post(self._api_url, json=post_data)
        resp.raise_for_status()
        return resp.json()

    def get_users(self):
        """
        Get existing users in OpenCTI.

        cursor: a str representing the cursor to continue pagination from

        returns: a generator that can be used for pagination purposes, in the form:
        {
            "data": {
                "users": {
                    "edges": [
                        {
                            "node": {
                                "id": "88ec0c6a-13ce-5e39-b486-354fe4a7084f",
                                "name": "admin",
                                "firstname": "Admin",
                                "lastname": "OpenCTI",
                                "user_email": "opencti+dev@example.com",
                                "external": true,
                                "otp_activated": null,
                                "created_at": "2022-08-24T18:20:18.987Z",
                                "__typename": "User"
                            },
                            "cursor": "WyJhZG1pbiIsInVzZXItLWYzZGJmYTNmLWI3OGQtNTc5OC1hY2Y0LWMxNjYzZGViNWFhZiJd"
                        },
                        ...
        """

        cursor = None
        while True:
            post_data = {
                "id": "UsersLinesPaginationQuery",
                "query": "query UsersLinesPaginationQuery(\n  $search: String\n  $count: Int!\n  $cursor: ID\n  $orderBy: UsersOrdering\n  $orderMode: OrderingMode\n) {\n  ...UsersLines_data_2ltyuX\n}\n\nfragment UserLine_node on User {\n  id\n  name\n  user_email\n  firstname\n  external\n  lastname\n  otp_activated\n  created_at\n}\n\nfragment UsersLines_data_2ltyuX on Query {\n  users(search: $search, first: $count, after: $cursor, orderBy: $orderBy, orderMode: $orderMode) {\n    edges {\n      node {\n        id\n        name\n        firstname\n        lastname\n        ...UserLine_node\n        __typename\n      }\n      cursor\n    }\n    pageInfo {\n      endCursor\n      hasNextPage\n      globalCount\n    }\n  }\n}\n",
                "variables": {
                    "search": "",
                    "count": 5,
                    "cursor": cursor,
                    "orderBy": "name",
                    "orderMode": "asc"
                }
            }

            resp = self._session.post(self._api_url, json=post_data)
            resp.raise_for_status()
            resp_dict = resp.json()
            users = resp_dict.get("data").get("users")
            page_info = users.get("pageInfo")
            if page_info["hasNextPage"]:
                cursor = page_info["endCursor"]
                yield resp_dict
            else:
                yield resp_dict
                break

    def get_user_account(self, user_id):
        """
        Gets information about a user account.

        user_id: a str representing the user's id

        return: a dict in the form:
        {
            "data": {
                "user": {
                    "id": "34a28402-5d0f-4742-b1e0-4bfbf323f6a0",
                    "name": "ExampleName",
                    "description": "ExampleDescription",
                    "external": false,
                    "user_email": "example@email.com",
                    "firstname": "ExampleFirstName",
                    "lastname": "ExampleLastName",
                    "language": "auto",
                    "api_token": "102141cf-f47e-4ff4-8169-0a400211ed05",
                    "otp_activated": null,
                    "roles": [
                        {
                            "id": "ad26a8a5-4c99-4654-b177-ead2d28daa09",
                            "name": "Default",
                            "description": "Default role associated to all users"
                        }
                    ],
                    "groups": {
                        "edges": []
                    },
                    "sessions": []
                }
            }
        }
        """

        post_data = {
            "id": "UserQuery",
            "query": "query UserQuery($id: String!) {user(id: $id) {id  name  ...User_user}}fragment User_user on User {id name description external user_email firstname lastname language api_token otp_activated roles {id name description} groups {edges {node {id name description}}} sessions {id created ttl}}",
            "variables": {
                "id": user_id
            }
        }

        resp = self._session.post(self._api_url, json=post_data)
        resp.raise_for_status()
        return resp.json()

def main():
    # Terraform passes all arguments as json in stdin
    args = json.load(sys.stdin)
    helper = OpenCTIAccountHelper(
        opencti_url=args["opencti_url"],
        email=args["admin_email"],
        password=args["admin_password"]
    )

    existing_user = helper.get_user_account(user_id=args["email"])

    # Attempt to see if the user exists already and if so use that token
    user_id = None
    for resp in helper.get_users():
        edges = resp["data"]["users"]["edges"]
        for node_dict in edges:
            # If the new user email == this existing user
            if args["email"] == node_dict["node"]["user_email"]:
                # Set the user's id
                user_id = node_dict["node"]["id"]
                break

    # The user doesn't exist, create the account
    if not user_id:
        created_account = helper.create_user_account(
            email=args["email"],
            password=args["password"],
            name=args["name"],
            first_name=args["first_name"],
            last_name=args["last_name"],
            description=args["description"]
        )
        user_id = created_account['data']['userAdd']['id']

    # Finally, get the user account's api token and print it as json        
    # This json is parsed by terraform
    user_account = helper.get_user_account(user_id=user_id)
    api_token    = user_account['data']['user']['api_token']
    print(json.dumps({"api_token": api_token}))

if __name__ == "__main__":
    main()