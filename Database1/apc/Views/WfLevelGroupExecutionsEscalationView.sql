	
CREATE view [apc].[WfLevelGroupExecutionsEscalationView]
AS
select wf_lvl_grp_exec.id id,wf_conf.name wfName,wf_esc_conf.escalation_due_days escalationDays,wf_lvl_grp_exec.wf_execution_id wfLevelExecutionId , 
DATEDIFF(day, wf_lvl_grp_exec.created_on, GETDATE()) daysCrossed ,wf_exec.req_id reqId ,wf_lvl_grp_exec.wf_execution_id wfExecutionId
,sec_grp_conf.wf_group_security_config_id wfGroupSecurityConfigId 
, (SELECT security_groupName
                 FROM    apc.wf_group_type_security_configuration 
                 WHERE id = mon_grp_exec.wf_group_security_config_id) AS executionMonitorGroup
, (SELECT security_groupName
                 FROM    apc.wf_group_type_security_configuration 
                 WHERE id = mon_grp_conf.wf_group_security_config_id) AS monitorGroup
, (SELECT security_groupName
                 FROM    apc.wf_group_type_security_configuration 
                 WHERE id = sec_grp_conf.wf_group_security_config_id) AS escalationGroup

from [apc].[wf_escalation_configuration] wf_esc_conf
left join [apc].[wf_level_group_configuration] wf_lvl_grop_conf on wf_esc_conf.[wf_level_group_config_id]=wf_lvl_grop_conf.id
left join [apc].[wf_configuration] wf_conf on wf_conf.id = wf_lvl_grop_conf.wf_config_id
inner join [apc].[wf_execution] wf_exec ON wf_exec.wf_config_id=wf_conf.id 
inner join [apc].[wf_level_group_execution] wf_lvl_grp_exec ON wf_exec.id =wf_lvl_grp_exec.[wf_execution_id] 
inner join [apc].[wf_level_group_security_group_configuration] sec_grp_conf on  sec_grp_conf.wf_level_group_config_id = wf_lvl_grop_conf.id
inner JOIN [apc].[wf_monitoring_group_configuration] mon_grp_conf ON mon_grp_conf.wf_config_id = wf_conf.id
inner JOIN [apc].[wf_monitoring_group_execution] mon_grp_exec ON mon_grp_exec.wf_execution_id = wf_exec.id 
where  DATEDIFF(day, wf_lvl_grp_exec.created_on, GETDATE()) >wf_esc_conf.escalation_due_days  and wf_lvl_grp_exec.escalation_mail_flag = 0 
and wf_lvl_grp_exec.status_id=1
