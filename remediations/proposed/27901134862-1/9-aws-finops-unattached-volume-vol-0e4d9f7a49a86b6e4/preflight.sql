-- preflight = suggested_remediation.preflight_query (verbatim, fully substituted upstream).
-- pass criterion: returns >=1 row.
SELECT volumeId FROM aws.ec2_native.volumes WHERE region = 'ap-southeast-2' AND volumeId = 'vol-0e4d9f7a49a86b6e4' AND status = 'available';
