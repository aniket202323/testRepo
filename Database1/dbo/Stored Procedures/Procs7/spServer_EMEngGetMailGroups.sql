CREATE PROCEDURE dbo.spServer_EMEngGetMailGroups
AS
Declare @EMGroups table (EG_Id int, ER_Address nVarChar(500), EG_Desc nVarChar(500), Standard_Header_Mode tinyint)
insert into @EMGroups (EG_Id, ER_Address, EG_Desc, Standard_Header_Mode)
Select d.EG_Id, r.ER_Address, g.Eg_Desc, r.Standard_Header_Mode
 	 from Email_Groups_Data d
 	 join email_recipients r on r.ER_ID = d.er_id
 	 join email_groups g on g.Eg_ID = d.eg_id
 	 where r.Is_Active = 1
Select EG_Id, ER_Address, EG_Desc, Standard_Header_Mode from @EMGroups
Select EG_Id, Table_Id, Key_Id from Email_Group_Xref where EG_Id in (Select EG_Id from @EMGroups)
