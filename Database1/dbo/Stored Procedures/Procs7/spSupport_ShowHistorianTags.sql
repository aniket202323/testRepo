Create Procedure [dbo].[spSupport_ShowHistorianTags]
AS
set nocount on
-- Tag must be the last field
Create Table #TagData([ID] int,[Description] VarChar(255),[Tag Type] VarChar(100),[Tag] VarChar(255))
Insert InTo #TagData([ID],[Description],[Tag Type],[Tag])
 	 Select Var_Id,Var_Desc,'Input Tag',Input_Tag From Variables Where Input_tag is not null and Ds_Id = 3
Insert InTo #TagData([ID],[Description],[Tag Type],[Tag])
 	 Select Var_Id,Var_Desc,'Output Tag',Output_Tag From Variables Where Output_Tag is not null
Insert InTo #TagData([ID],[Description],[Tag Type],[Tag])
 	 Select Var_Id,Var_Desc,'Lower Entry Tag',LEL_Tag From Variables Where LEL_Tag is not null
Insert InTo #TagData([ID],[Description],[Tag Type],[Tag])
 	 Select Var_Id,Var_Desc,'Lower Reject Tag',LRL_Tag From Variables Where LRL_Tag is not null
Insert InTo #TagData([ID],[Description],[Tag Type],[Tag])
 	 Select Var_Id,Var_Desc,'Lower Warning Tag',LWL_Tag From Variables Where LWL_Tag is not null
Insert InTo #TagData([ID],[Description],[Tag Type],[Tag])
 	 Select Var_Id,Var_Desc,'Lower User Tag',LUL_Tag From Variables Where LUL_Tag is not null
Insert InTo #TagData([ID],[Description],[Tag Type],[Tag])
 	 Select Var_Id,Var_Desc,'Target Tag',Target_Tag From Variables Where Target_Tag is not null
Insert InTo #TagData([ID],[Description],[Tag Type],[Tag])
 	 Select Var_Id,Var_Desc,'Upper User Tag',UUL_Tag From Variables Where UUL_Tag is not null
Insert InTo #TagData([ID],[Description],[Tag Type],[Tag])
 	 Select Var_Id,Var_Desc,'Upper Warning Tag',UWL_Tag From Variables Where UWL_Tag is not null
Insert InTo #TagData([ID],[Description],[Tag Type],[Tag])
 	 Select Var_Id,Var_Desc,'Upper Reject Tag',URL_Tag From Variables Where URL_Tag is not null
Insert InTo #TagData([ID],[Description],[Tag Type],[Tag])
 	 Select Var_Id,Var_Desc,'Upper Entry Tag',UEL_Tag From Variables Where UEL_Tag is not null
Insert InTo #TagData([ID],[Description],[Tag Type],[Tag])
 	 Select Var_Id,Var_Desc,'Data Quality Tag',DQ_Tag From Variables Where DQ_Tag is not null
Insert InTo #TagData([ID],[Description],[Tag Type],[Tag])
 	 Select ec.PU_Id,substring(em.Model_Desc,1,100),substring(ec.EC_Desc,1,100), right(convert(varchar(7000),Value),datalength(convert(varchar(7000),value))-3)
 	 From Event_configuration_Values ecv
 	 Join event_configuration_Data ecd on ecd.Ecv_ID = ecv.ECV_Id
 	 Join event_configuration ec on ec.EC_Id = ecd.EC_ID
 	 Join Ed_models em on  em.ED_Model_Id = ec.ED_Model_Id
 	 Where  ecv.Value is not null  and left(convert(varchar(7000),value),3) = 'PT:'
select [ID] ,[Description] ,[Tag Type],LTRIM(RTRIM([Tag])) [Tag] from #TagData Order by Tag
Drop table #TagData
set nocount off
