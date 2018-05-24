import boto3, os, zipfile , argparse, datetime , subprocess

current_time = datetime.datetime.now().strftime("%Y-%m-%d-%H-%M-%S")

# zip lambda project folder
def lambdazip():
    newzip = zipfile.ZipFile('Applications\\Lambda_packages\\lambda_package.zip', 'w')
    os.chdir('Applications\\Lambda')
    for root, dirs, files in os.walk('.'):
        for i in files:
            if "test" not in i:
                newzip.write(os.path.relpath(os.path.join(root,i)))
    os.chdir("..")
    os.chdir("..")
    newzip.close()

# check test status ( fail / pass)
def check_tests():
    filename = run_tests()
    test_report_file = os.path.abspath(os.path.join(os.path.dirname(__file__), 'Applications/Lambda/test_results/'+filename))
    with open(test_report_file, 'r') as test_report:
        data = test_report.read()
        print(data)
        if 'failed' in data or 'error' in data:
            return False
        return True

# run tests and write them in a log file
def run_tests():
    filename = "pytest_report"+current_time+".log"
    os.system('pytest .\Applications\Lambda\\test.py -v > .\Applications\Lambda\\test_results/' + filename)
    return filename

# run the tests , check if passed
if (check_tests()):
    print("***********Tests passed , Zipping lambda function***********")
    lambdazip()
    os.chdir("Terraform_config")
    if not os.path.isdir("Terraform_config\.terraform"):
        subprocess.call(["terraform","init"])

    subprocess.call(["terraform","plan","-var","lambda_zip_file_name=lambda_package.zip"])
    subprocess.call(["terraform","apply","-var","lambda_zip_file_name=lambda_package.zip","-auto-approve"])

else:
    print('**********Tests failed**********')
