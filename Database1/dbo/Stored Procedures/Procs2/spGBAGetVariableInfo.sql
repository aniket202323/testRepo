Create Procedure dbo.spGBAGetVariableInfo 
 	 @ID int,
 	 @VarDesc nVarChar(50),
 	 @GetMaster tinyint   AS
DECLARE @MasterUnit int, @UnitID int
IF @GetMaster = 1 
  BEGIN
   if @VarDesc is null 
      select vars.*, pu.master_unit
      from variables vars 
        join prod_units pu  on pu.pu_id = vars.pu_id  
        where vars.var_id = @Id
    else
      select a.*, b.master_unit from variables a 
        join prod_units b on b.pu_id = a.pu_id
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
    select * from variables where pu_id = @Id order by var_desc
