CREATE PROCEDURE dbo.spServer_OPCGetVariables
@User_Id int
AS
-- Variables
Select     1 as type, v.Var_Id as VarKey,
           convert(nVarChar(50),Replace(Replace((Replace(l.PL_Desc,'.','') + '.' + Replace(u.PU_Desc,'.','')),' ',''),':','')) as ParentItemID,
           convert(nVarChar(50),Replace(Replace(Replace(v.Var_Desc,'.',''),' ',''),':','')) as ItemID,
           t.Data_Type_Desc,
           convert(nVarChar(10),'Write') as Access
  from          Variables_Base   as v
           join Prod_Units  as u on v.PU_Id = u.PU_Id
           join Prod_Lines  as l on u.PL_Id = l.PL_Id
           join Data_Type   as t on v.Data_Type_Id = t.Data_Type_Id
  where    v.Var_Id > 0
    and    v.Data_Type_Id <= 3
-- Production Units
union
Select     2 as type, u.PU_Id as VarKey,
           convert(nVarChar(50),Replace(Replace(Replace(l.PL_Desc,'.',''),' ',''),':','')) as ParentItemID,
           convert(nVarChar(50),Replace(Replace(Replace(u.PU_Desc,'.',''),' ',''),':','')) as ItemID,
           convert(nVarChar(10),'String') as DataType,
           convert(nVarChar(10),'NoValue') as Access
  from          Prod_Units  as u
           join Prod_Lines  as l on u.PL_Id = l.PL_Id
  where    u.PU_Id > 0
-- Topic 100
union
Select     100 as type, u.PU_Id as VarKey,
           convert(nVarChar(50),Replace(Replace((Replace(l.PL_Desc,'.','') + '.' + Replace(u.PU_Desc,'.','')),' ',''),':','')) as ParentItemID,
           convert(nVarChar(50),'Topic100') as ItemID,
           convert(nVarChar(10),'String') as DataType,
           convert(nVarChar(10),'NoValue') as Access
  from          Prod_Units  as u
           join Prod_Lines  as l on u.PL_Id = l.PL_Id
  where    u.PU_Id > 0
order by type, VarKey
Declare @OPCVarProperties Table(Var_Type int, Var_Id int, Property int, Data_Type int, Property_Value nvarchar(200) COLLATE DATABASE_DEFAULT)
-- Variable Properties
  -- Engineering Units Property
  Insert Into    @OPCVarProperties(Var_Type, Var_Id, Property, Data_Type, Property_Value)
         Select  1, Var_ID, 100, 3, Eng_Units
           from  Variables_Base
           where Eng_Units is not null and Var_Id > 0
  -- Description Property
  Insert Into    @OPCVarProperties(Var_Type, Var_Id, Property, Data_Type, Property_Value)
         Select  1, Var_ID, 101, 3, Var_Desc
           from  Variables_Base
           where Var_Desc is not null and Var_Id > 0
  -- VarId Property
  Insert Into    @OPCVarProperties(Var_Type, Var_Id, Property, Data_Type, Property_Value)
         Select  1, Var_ID, 5009, 1, Var_Id
           from  Variables_Base
           where Var_Id > 0
  -- PUId Property
  Insert Into    @OPCVarProperties(Var_Type, Var_Id, Property, Data_Type, Property_Value)
         Select  1, Var_ID, 5010, 1, PU_Id
           from  Variables_Base
           where Var_Id > 0 and PU_Id > 0
-- Production Unit Properties
  -- Description Property
  Insert Into    @OPCVarProperties(Var_Type, Var_Id, Property, Data_Type, Property_Value)
         Select  2, PU_ID, 101, 3, PU_Desc
           from  Prod_Units
           where PU_Desc is not null and PU_Id > 0
  -- PUId Property
  Insert Into    @OPCVarProperties(Var_Type, Var_Id, Property, Data_Type, Property_Value)
         Select  2, PU_ID, 5010, 1, PU_Id
           from  Prod_Units
           where PU_Id > 0
  -- MUId Property
  Insert Into    @OPCVarProperties(Var_Type, Var_Id, Property, Data_Type, Property_Value)
         Select  2, PU_ID, 5011, 1, case when (Master_Unit is null) then PU_Id else Master_Unit end
           from  Prod_Units
           where PU_Id > 0
  -- PLId Property
  Insert Into    @OPCVarProperties(Var_Type, Var_Id, Property, Data_Type, Property_Value)
         Select  2, PU_ID, 5012, 1, PL_Id
           from  Prod_Units
           where PU_Id > 0
-- Final Properties Result Set
Select     p.Var_Type,
           p.Var_Id,
           p.Property,
           t.Data_Type_Desc,
           p.Property_Value
  from          @OPCVarProperties as p
           join Data_Type         as t on p.Data_Type = t.Data_Type_id
  order by p.Var_Type, p.Var_Id, p.Property
