CREATE PROCEDURE dbo.spEM_BOMSearchSetup
AS
Select Path_Id,Path_Code from Prdexec_Paths order by Path_Code
select PP_Status_Id,PP_Status_Desc from Production_Plan_Statuses order by PP_Status_Desc
select Table_Field_Id,Table_Field_Desc from Table_Fields  WHERE TABLEID In (26,28) order by Table_Field_Desc
select DS_Id,DS_Desc from Data_Source where DS_Id>0 order by DS_Desc
