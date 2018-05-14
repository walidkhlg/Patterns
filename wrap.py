import boto3, os, zipfile , argparse




def lambdazip(path):
    try:
        os.remove('serverless.zip')
    except OSError:
        pass
    newZip = zipfile.ZipFile('serverless.zip','a')
    for root, dirs, files in os.walk(path):
        for i in files:
            newZip.write(os.path.join(root, i), i, zipfile.ZIP_DEFLATED)
    newZip.close()



parser = argparse.ArgumentParser(description='Wrap lambda to s3')
parser.add_argument('-p','--path',help='Path to lambda poject folder',default='C:\\Users\\to124924\\PycharmProjects\\serverls')
parser.add_argument('-b','--bucket' ,help='bucket name for lambda function',default='s3-lambda-walid')
params = parser.parse_args()



lambdazip(params.path)
session = boto3.Session(profile_name='compte-lab-26')
s3 = session.client('s3')
#s3.create_bucket(Bucket=params.bucket)
s3.upload_file('serverless.zip',params.bucket,'serverless.zip')
