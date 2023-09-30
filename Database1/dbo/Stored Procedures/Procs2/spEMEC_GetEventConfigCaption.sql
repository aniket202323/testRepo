Create Procedure dbo.spEMEC_GetEventConfigCaption
@PU_Id int,
@User_Id int,
@EventConfigCaption nvarchar(150) OUTPUT,
@PU_Desc nvarchar(50) OUTPUT
AS
declare @PL_Desc nvarchar(50)
select @PL_Desc = prod_lines.pl_desc, @PU_Desc = prod_units.pu_desc from prod_units
join prod_lines on prod_units.pl_id = prod_lines.pl_id
where prod_units.pu_id = @PU_Id
select @EventConfigCaption = '[' + @PL_Desc + '/' + @PU_Desc + ']'
