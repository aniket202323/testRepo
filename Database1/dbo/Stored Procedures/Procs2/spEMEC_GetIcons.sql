Create Procedure dbo.spEMEC_GetIcons
@User_Id int
AS
select * from Icons order by icon_desc
