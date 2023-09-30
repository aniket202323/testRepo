Create Procedure dbo.spXLAGetVariableInfo
@ID int,
@VarDesc varchar(50),
@GetMaster tinyint,
@SearchString varchar(50) = NULL
AS
DECLARE @MasterUnit int, @UnitID int
IF @GetMaster = 1 
  BEGIN
   if @VarDesc is null 
      select vars.*, pu.master_unit 
 	    from variables vars 
        join prod_units pu  on pu.pu_id = vars.pu_id  
        where vars.var_id = @Id
    else
      select a.*, b.master_unit
 	    from variables a
        join prod_units b  on b.pu_id = a.pu_id
         where a.var_desc = @VarDesc
  END
ELSE if @GetMaster = 2
  BEGIN
   if @VarDesc is null 
      select * from variables  where var_id = @Id 
    else
      select * from variables where var_desc = @VarDesc
  END
ELSE if @GetMaster = 3
  Begin
    If @SearchString Is NULL 
      select * from variables where pu_id = @Id order by var_desc
    Else
      select * from variables where pu_id = @Id and var_desc like '%' + ltrim(rtrim(@SearchString)) + '%' order by var_desc
  End
