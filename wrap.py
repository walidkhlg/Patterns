import boto3, os, zipfile , argparse, datetime


current_time = datetime.datetime.now().strftime("%Y-%m-%d-%H-%M-%S")

# zip lambda project folder
def lambdazip(path):
    zipname = 'lambda_function'+current_time+'.zip'
    newzip = zipfile.ZipFile('Lambda_packages\\'+zipname, 'w')
    os.chdir('Lambda')
    for root, dirs, files in os.walk(path):
        for i in files:
            if "test" not in i:
                newzip.write(os.path.relpath(os.path.join(root,i)))
    newzip.close()
    return zipname

# check test status ( fail / pass)
def check_tests():
    filename = run_tests()
    test_report_file = os.path.abspath(os.path.join(os.path.dirname(__file__), 'Lambda/test_results/'+filename))
    with open(test_report_file, 'r') as test_report:
        data = test_report.read()
        print(data)
        if 'failed' in data or 'error' in data:
            return False
        return True

# run tests and write them in a log file
def run_tests():
    filename = "pytest_report"+current_time+".log"
    os.system('pytest .\Lambda\\test.py -v > .\Lambda\\test_results/' + filename)
    return filename

parser = argparse.ArgumentParser(description='package lambda for deplyment')
parser.add_argument('-p', '--path', help='Path to lambda poject folder', default='C:\\Users\\to124924\\Desktop\\patterns\\Lambda\\')
parser.add_argument('-b', '--bucket', help='bucket name for app', default='app-bucket-201847')
params = parser.parse_args()

# run the tests , check if passed
if (check_tests()):
    print("***********Tests passed , Zipping lambda function***********")
    #s3_client = boto3.client('s3')
    #s3_client.upload_file('App/index.php','')
    lambda_package = lambdazip(params.path)
    #os.system('terraform apply -var lambda_zip_file_name ='+lambda_package)
else:
    print('**********Tests failed**********')
