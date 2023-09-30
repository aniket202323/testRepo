	
CREATE VIEW apc.WorkflowLevelGroupExecutionsView 
AS
	SELECT 
		 wle.id AS workflowLevelGroupExecutionId, wfe.id AS workflowExecutionId, wfc.name AS workflowName, wfc.revision, wfe.created_on AS workflowStartedOn, wfe.created_by AS workflowStartedBy, wfe.req_id AS requestId, wfe.req_name AS requestName, wflg.level_id AS levelId, wflg.level_name AS levelName, wflg.group_name AS groupName, wfaa.activty_id AS activityId, wfgt.group_name AS groupType, wle.created_on AS levelGroupCreatedOn, wfs.id as statusId, wfs.name AS status,wfgtsc.security_groupName as securityGroupName, wle.recieved_reverification as recievedReverification,
		 (SELECT sc.security_groupName
		  FROM  apc.wf_group_type_security_configuration AS sc INNER JOIN
						  apc.wf_execution AS wfe ON wfe.id = wmge.wf_execution_id
		  WHERE (sc.id = wmge.wf_group_security_config_id)) AS monitorSecurityGroup, wmge.id AS monitorGroupId
	FROM   apc.wf_level_group_execution AS wle INNER JOIN
				 apc.wf_execution AS wfe ON wle.wf_execution_id = wfe.id INNER JOIN
				 apc.wf_status AS wfs ON wfs.id = wle.status_id INNER JOIN
				 apc.wf_configuration AS wfc ON wfc.id = wfe.wf_config_id INNER JOIN
				 apc.wf_level_group_configuration AS wflg ON wflg.id = wle.wf_level_group_config_id INNER JOIN
				 apc.wf_group_type AS wfgt ON wfgt.id = wflg.wf_group_type_id INNER JOIN
				 apc.wf_level_group_security_group_configuration AS wflgsg ON wflgsg.wf_level_group_config_id = wflg.id INNER JOIN
				 apc.wf_group_type_security_configuration AS wfgtsc ON wfgtsc.id = wflgsg.wf_group_security_config_id LEFT OUTER JOIN
				 apc.wf_activties_association AS wfaa ON wfaa.wf_level_group_execution_id = wle.id LEFT OUTER JOIN
				 apc.wf_monitoring_group_execution AS wmge ON wmge.wf_execution_id = wfe.id
