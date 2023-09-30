Create Procedure dbo.spSupport_ValidateDefaultReportServerParameters
AS
Print 'Validate Parameters and Paths'
Select Hostname,Parm_id,Value,'SQL Table:  Site_Parameters' From Site_Parameters where parm_id in (101,102)
Select Hostname,Parm_id,Value,User_id,'SQL Table:  User_Parameters' From User_Parameters where parm_id in (101,102)
Select Distinct(server),Count(*) as Number_Of_Records,'SQL Table:  Dashboard_Gallery_Generator_Servers' From Dashboard_Gallery_Generator_Servers group by server
Select Distinct(Dashboard_Report_Server),Count(*) as Number_Of_Records,'SQL Table:  Dashboard_Reports' from Dashboard_Reports group by Dashboard_Report_Server
Select Distinct(Dashboard_Key),Count(*) as Number_Of_Records,'SQL Table:  Dashboard_Users' from Dashboard_Users group by Dashboard_Key
Select Distinct(Dashboard_Key),Count(*) as Number_Of_Records,'SQL Table:  Dashboard_Statistics' from Dashboard_Statistics group by Dashboard_Key
Select Distinct(RDP.Value),RTP.RP_ID,RP.RP_Name,Count(*) as Number_Of_Records,'SQL Table:  Report_Definition_Parameters' from Report_Definition_Parameters RDP 
 	 Join Report_Type_Parameters RTP on RDP.RTP_Id = RTP.RTP_Id
 	 Join Report_Parameters RP on RP.RP_Id = RTP.RP_Id
 	 Where RTP.RP_Id in (35,36,42,43) and RDP.Value <> '' group by RDP.Value,RTP.RP_Id,RP.RP_Name
Select Distinct(Engine_Name), Count(*) as Number_Of_Records,'SQL Table:  Report_Engines' from Report_Engines group by Engine_Name 	 
Select Distinct(Default_Value),RP_ID,RP_Name,Count(*) as Number_Of_Records,'SQL Table:  Report_Parameters' From Report_Parameters 
 	 where rp_id in (35,36,42,43) group by Default_Value,RP_ID,RP_Name
Select Distinct(RTP.Default_Value),RTP.RP_Id,RP.RP_Name,Count(*) as Number_Of_Records,'SQL Table:  Report_Type_Parameters' From Report_Type_Parameters RTP
 	 Join Report_Parameters RP on RP.RP_Id = RTP.RP_Id
 	 where RTP.RP_Id in (35,36,42,43) and RTP.Default_Value <> ''
 	 group by RTP.Default_Value,RTP.RP_Id,RP.RP_Name
Select Distinct(Template_Path),Count(*) as Number_Of_Records,'SQL Table:  Report_Types' From Report_Types  group by Template_Path
Select distinct(Url),Count(*) as Number_Of_Records,'SQL Table:  Report_Tree_Nodes' from Report_Tree_Nodes group by URL 
Select sp.HostName,sp.Parm_Id,p.parm_name,sp.value,'SQL Table:  Site_Parameters' From Site_Parameters sp
 	 Join Parameters p on p.Parm_Id = sp.parm_id 	 
 	 where sp.Parm_Id in (10,27,29,55,126,165,166,167)
Select up.HostName,up.Parm_Id,p.parm_name,up.User_Id,u.username,up.Value,'SQL Table:  User_Parameters' from User_parameters up
 	 Join Parameters p on p.Parm_Id = up.parm_id 	 
 	 Join Users u on up.User_Id = u.User_Id
 	 where up.User_Id in (17,22,23,24,25,29,36) and up.Parm_Id in (50,51,52,53,101,102,126,146) order by up.Parm_Id
 	 
