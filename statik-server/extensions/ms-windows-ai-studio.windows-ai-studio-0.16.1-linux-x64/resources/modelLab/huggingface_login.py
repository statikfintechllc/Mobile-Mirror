import argparse
import huggingface_hub
import huggingface_hub.errors
from modelLab import logger

def exitWithError(errorStr):
    logger.error(errorStr)
    raise Exception(errorStr)

def exitWithNotLogin():
    logger.info("User is not logged in.")
    exit(1)

def is_login():
    try:
        # Try to get user information
        user = huggingface_hub.whoami()
        if len(user) > 0:
            logger.info("User is logged in.")
        else:
            exitWithNotLogin()
    except huggingface_hub.errors.LocalTokenNotFoundError:
        exitWithNotLogin()
    except Exception as e:
        exitWithError(f"Error checking login status: {e}")

def do_login(token):
    try:
        # Try to log in with the provided token
        huggingface_hub.login(token=token)
        user = huggingface_hub.whoami()
        if len(user) > 0:
            logger.info("Login successful.")
        else:
            exitWithError("Login failed.")
    except Exception as e:
        exitWithError(f"Error during login: {e}")

def do_logout():
    try:
        huggingface_hub.logout()
        logger.info("Logout successful.")
    except Exception as e:
        exitWithError(f"Error during logout: {e}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Hugging Face login script')
    subparsers = parser.add_subparsers(dest='command')

    # Define the islogin sub - command
    parser_islogin = subparsers.add_parser('islogin', help='Check if the user is logged in')

    # Define the login sub - command
    parser_login = subparsers.add_parser('login', help='Log in using a token')
    parser_login.add_argument('--token', type=str, required=True, help='Hugging Face access token')

    # Define the logout sub - command
    parser_logout = subparsers.add_parser('logout', help='Log out from Hugging Face')

    args = parser.parse_args()

    if args.command == 'islogin':
        is_login()
    elif args.command == 'login':
        do_login(args.token)
    elif args.command == 'logout':
        do_logout()
    else:
        parser.print_help()
    