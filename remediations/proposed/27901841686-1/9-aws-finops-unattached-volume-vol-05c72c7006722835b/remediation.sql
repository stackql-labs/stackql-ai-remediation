-- canonical kill SQL (documentation only; vendor CLI does the work at merge).
DELETE FROM aws.ec2.volumes WHERE region = 'ap-southeast-2' AND VolumeId = 'vol-05c72c7006722835b';
