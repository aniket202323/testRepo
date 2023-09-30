CREATE PROCEDURE dbo.spEM_LoadInformation
  @ObjectType nVarChar(2),
  @Id         int
  AS
  --
  -- Delcare local variables.
  --
  -- variable information
  --
 IF @ObjectType = 'ae'
  BEGIN
    --Parents
    SELECT v.Event_Type,v.Sampling_Type,v.Var_Id, v.Var_Desc, v.PU_Id, v.PUG_Id, v.PUG_Order, v.PVar_Id, v.DS_Id,
         v.Data_Type_Id, v.Var_Precision, v.Eng_Units, v.Group_Id, v.Comment_Id, v.External_Link, 
 	    v.SPC_Calculation_Type_Id, v.SPC_Group_Variable_Type_Id, [System] = isnull(v.System,0), Sampling_Interval = isnull(v.Sampling_Interval, 0),
 	  	 [Is_Active] = isnull(convert(int,v.Is_Active),1),inSOA = Case WHEN vae.Var_id is null then 0 else 1 end
    FROM Variables v
    Join  PU_Groups pug on pug.PUG_Id = v.PUG_Id and  PUG_Desc <> 'Model 5014 Calculation'
    Left Join Variables_Aspect_EquipmentProperty vae on vae.Var_Id = v.Var_Id  
    Where v.PU_Id = @Id and v.PVar_Id is NULL and v.PU_Id <> 0 
    ORDER BY v.PUG_Order, Var_Desc
    --Children
    SELECT Event_Type,Sampling_Type,Var_Id, Var_Desc, PU_Id, PUG_Id, PUG_Order, PVar_Id, DS_Id,
         Data_Type_Id, Var_Precision, Eng_Units, Group_Id, Comment_Id, External_Link, SPC_Group_Variable_Type_Id, Spec_Id, [System] = isnull(System,0), 
 	     Sampling_Interval = isnull(Sampling_Interval, 0),[Is_Active] = isnull(convert(int,Is_Active),1),Pei_id,Event_Subtype_ID
    FROM Variables Where PU_Id = @Id and PVar_Id is not NULL and PU_Id <> 0 
    ORDER BY PUG_Order, Var_Desc
  END
 ELSE IF @ObjectType = 'cb'
  BEGIN
    --
    -- 
    -- Build a reason tree
    --
      SELECT  ertd.Tree_Name_Id,ertd.Event_Reason_Tree_Data_Id,ertd.Event_Reason_Id,ertd.Event_Reason_Level,ertd.Parent_Event_R_Tree_Data_Id
      FROM  Event_Reason_Tree_Data ertd
      Join Event_Reasons er on er.Event_Reason_Id = ertd.Event_Reason_Id
      WHERE ertd.Tree_Name_Id = @Id
      ORDER BY ertd.Event_Reason_Level,er.Event_Reason_Name
   --
   --
      SELECT Event_Reason_Level_Header_Id,Tree_Name_Id,Level_Name,Reason_Level 
         FROM Event_Reason_Level_Headers 
         WHERE Tree_Name_Id = @Id
         ORDER BY Reason_Level
      Select a.ERCD_Id,a.ERC_Id,a.Event_Reason_Tree_Data_Id,b.Event_Reason_Level,ERC_Desc
 	 From Event_Reason_Category_Data a
 	 Join Event_Reason_Tree_Data b on a.Event_Reason_Tree_Data_Id = b.Event_Reason_Tree_Data_Id
 	 Join Event_Reason_Catagories c on c.ERC_Id = a.ERC_Id
 	 Where b.Tree_Name_Id = @Id and Propegated_From_ETDId is null
  END
 ELSE IF @ObjectType = 'bw'
   BEGIN
   --
   --  Build Reason tree names
   --
    SELECT Tree_Name_Id, Tree_Name,Group_Id FROM Event_Reason_Tree
    --
    -- Get Event reasons  
    --
    SELECT Event_Reason_Id, Event_Reason_Name, Event_Reason_Code, Comment_Id, External_Link,Comment_Required,Group_Id
      FROM Event_Reasons
   END
 ELSE IF @ObjectType = 'cn'
   BEGIN
   --
   --  Build Products Line
   --
   -- Get product records.
 	 Create Table #Prods ( Prod_Id Int, Prod_Desc nvarchar(50), Prod_Code nvarchar(50), Comment_Id Int Null, External_Link nvarchar(255) Null,Product_Family_Id Int,Char_Id Int Null,inSoa int)
 	 Insert Into #Prods (Prod_Id,Prod_Desc,Prod_Code,Comment_Id,External_Link,Product_Family_Id,inSoa)
    SELECT a.Prod_Id, Prod_Desc, Prod_Code, Comment_Id, External_Link,Product_Family_Id,inSOA = Case WHEN b.Prod_Id is null then 0 else 1 end
     FROM Products a
     Left Join Products_Aspect_MaterialDefinition b on b.Prod_Id = a.Prod_Id 
 	  WHERE a.Prod_Id <> 1 and Product_Family_Id = @Id
    Update #Prods set Char_Id = (select Min(Char_Id)  From Characteristics where  Characteristics.prod_Id = #Prods.Prod_Id) 
 	 Select * from #Prods
   -- Get product group records.
--    SELECT Product_Grp_Id, Product_Grp_Desc, Comment_Id, External_Link FROM Product_Groups
   -- Get product group data records.
    SELECT PGD_Id, Product_Grp_Id, Prod_Id
      FROM Product_Group_Data
      Where Prod_Id in ( SELECT Prod_Id FROM Products WHERE Prod_Id <> 1 and Product_Family_Id = @Id)
   END
 ELSE IF @ObjectType = 'ao'
   BEGIN
   --
   --  Build Properties (Prop)
   --
   -- Get characteristic records.
   --
Declare @Parent Int
Create Table #C (Char_Id Int, Char_Desc nvarchar(50), Prop_Id Int, Comment_Id Int Null, 
 	  	  External_Link nvarchar(255) Null,Extended_Info nvarchar(255) Null,Exception_Type TinyInt Null,Derived_From_Parent Int Null,Prod_Id Int Null)
Insert into #C (Char_Id, Char_Desc, Prop_Id, Comment_Id,External_Link ,Extended_Info,Exception_Type,Derived_From_Parent,Prod_Id)
   SELECT Char_Id, Char_Desc, Prop_Id, Comment_Id, External_Link,Extended_Info,Exception_Type,  Null,Prod_Id
     FROM Characteristics c 
     WHERE Prop_Id = @Id -- and prod_Id is null and characteristic_type is null
Declare c Cursor For
 Select Distinct Derived_From_Parent
   From Characteristics c 
     WHERE Prop_Id = @Id and Derived_From_Parent is Not Null
Open C
CLoop:
 Fetch Next From c InTo @Parent
 If @@Fetch_Status = 0
  Begin
    Update #C set Derived_From_Parent = @Parent Where Char_Id = @Parent
    Goto cLoop
  End
Close c
Deallocate c
Select * from #c
Drop Table #c
   -- Get Characteristic Groups
   SELECT Characteristic_Grp_Id, Characteristic_Grp_Desc, Prop_Id, Comment_Id, External_Link
    FROM Characteristic_Groups WHERE Prop_Id = @Id
   -- Get Characteristic Group Data
   SELECT CGD_Id, cgd.Characteristic_Grp_Id, cgd.Char_Id 
      FROM Characteristic_Group_Data cgd
      JOIN Characteristic_Groups cg ON  cgd.Characteristic_Grp_Id = cg.Characteristic_Grp_Id
    WHERE cg.Prop_Id = @Id
  END
 ELSE IF @ObjectType = 'bf'
   BEGIN
    -- Make sure all approved transactions have a group Id
    UPDATE Transactions set Transaction_Grp_Id = 1 WHERE  Transaction_Grp_Id is NULL and Approved_By IS NOT NULL
    -- Get approved transaction records.
    SELECT Trans_Id, Trans_Desc, Approved_By, Comment_Id,Transaction_Grp_Id,Trans_Type_Id FROM Transactions
 	 WHERE Approved_By IS NOT NULL and Trans_Type_Id <> 5
  END
 ELSE IF @ObjectType = 'al'
   BEGIN
    --  Product Group
     Select Distinct Product_Family_Id 
 	  From  Product_Group_Data pgd
 	  Join Products p on p.Prod_Id = pgd.Prod_Id 
 	 WHERE Product_Grp_Id = @Id
    END
 ELSE IF @ObjectType = 'ad'
   BEGIN
 -- Get production unit records.
  Create Table #ProdUnits (PU_Id Int, PU_Desc nvarchar(50),Master_order Int, PU_Order Int, PL_Id Int, Master_Unit Int, Group_Id Int,
 	  	  	  	  	  	    Comment_Id Int, Extended_Info nvarchar(255), External_Link nvarchar(255),Waste_TN_Id Int,Timed_TN_Id Int,
 	  	  	  	  	  	   Timed_Event_Association Int,Uses_Start_Time Int,BOMSPECS Int)
  Insert into #ProdUnits(PU_Id, PU_Desc,Master_order,PU_Order,PL_Id, Master_Unit, Group_Id,Comment_Id,Extended_Info,External_Link,Waste_TN_Id,
 	  	  	  	  	  	  Timed_TN_Id,Timed_Event_Association,Uses_Start_Time,BOMSPECS)
  SELECT pu.PU_Id, PU_Desc, 	 Master_order= case When (Master_Unit IS Null) and (PU_Order is NuLL)   Then  pu.PU_Id
 	  	  	  	  	       When (Master_Unit IS Not Null) and (select PU_Order from prod_units where pu_Id = pu.Master_Unit) is Null Then pu.Master_Unit
  	   	  	  	  	       When Master_Unit IS Null  Then PU_Order
 	  	  	  	  	       Else (select convert(Int,PU_Order) from prod_units where pu_Id = pu.Master_Unit) 
 	  	  	  	  	       End ,
 	  PU_Order , PL_Id, Master_Unit, Group_Id, Comment_Id, Extended_Info, External_Link,
 	  Waste_TN_Id = pe2.Name_Id,Timed_TN_Id = pe.Name_Id,Timed_Event_Association = Coalesce(pu.Timed_Event_Association,0),
 	  Uses_Start_Time = Coalesce(pu.Uses_Start_Time,0),0
    FROM Prod_Units pu
    LEFT JOIN Prod_Events pe  ON  pe.PU_Id = pu.PU_Id AND pe.Event_type = 2    -- Delay (timed)
    LEFT JOIN Prod_Events pe2 ON pe2.PU_Id = pu.PU_Id AND pe2.Event_type = 3   -- Waste 
    WHERE pu.PU_Id > 0
  Update #ProdUnits Set BOMSPECS = 1 where Pu_Id in (Select Distinct PU_Id = Coalesce(pu.Master_Unit,pu.pu_Id)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 from Variables v
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 Join Prod_Units pu on v.pu_Id = pu.Pu_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 Join Specifications s on s.spec_Id = v.Spec_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 Join Product_Properties pp on pp.Prop_Id = s.Prop_Id and  pp.Property_Type_Id = 2)
  Select * from #ProdUnits ORDER BY PL_Id,Master_order,Master_Unit,PU_Order
  Drop Table #ProdUnits
  -- Get production group records.
  SELECT PUG_Id, PU_Id,Group_Id, PUG_Desc, PUG_Order, Comment_Id, External_Link
    FROM PU_Groups
    WHERE PU_Id in( select pu_Id from Prod_Units where pl_Id = @Id)
    ORDER BY PUG_Order, PUG_Desc
  END
 ELSE IF @ObjectType = 'ar'
  Begin
--Parent
      SELECT Spec_Id, Spec_Desc, Prop_Id, Data_Type_Id, Spec_Precision, Comment_Id, Group_Id, External_Link,Spec_Order,Extended_Info,Tag,Eng_Units,Array_Size,Parent_Id
      FROM Specifications 
 	   Where Prop_Id = @Id and Parent_Id is null
 	   ORDER BY Spec_Order 
--Children
      SELECT Spec_Id, Spec_Desc, Prop_Id, Data_Type_Id, Spec_Precision, Comment_Id, Group_Id, External_Link,Spec_Order,Extended_Info,Tag,Eng_Units,Array_Size,Parent_Id
      FROM Specifications 
 	   Where Prop_Id = @Id and Parent_Id is not null
 	   ORDER BY Parent_Id, Spec_Desc
  End
 ELSE IF @ObjectType = 'ck'
  Begin
  SELECT Sheet_Id, Sheet_Desc, s.Is_Active, Comment_Id, External_Link,Sheet_Group_Id,Group_Id,Event_Type,s.Sheet_Type, st.App_Id
 	 FROM Sheets s
 	 left Join Sheet_Type st  On st.Sheet_Type_Id  = s.Sheet_Type
 	  Where (st.Is_Active = 1 or s.Sheet_Type is null) and Sheet_Group_Id = @Id
   	  Order by Sheet_Desc
  End
 ELSE IF @ObjectType = 'bb'
  Begin
 	   -- Get phrase records.
 	   SELECT Phrase_Id, Data_Type_Id, Phrase_Value, Phrase_Order, Active, Comment_Required 
 	  	 FROM Phrase
 	  	 Where  Data_Type_Id = @Id
  End
 ELSE IF @ObjectType = 'aw'
  Begin
 	   SELECT us.Security_Id, us.User_Id,us.Group_Id,us.Access_Level
 	  	 FROM User_Security us
      JOIN Users u on u.User_Id = @Id
 	  	 Where  us.User_Id = @Id and u.Role_Based_Security = 0
     SELECT Distinct User_Role_Security_Id, Role_User_Id, u.User_Id, GroupName = Coalesce(u.UserName, '')
       FROM User_Role_Security ur
         JOIN Users u on u.User_Id = ur.User_Id
         WHERE u.User_Id = @Id
       Order By GroupName
  End
 ELSE IF @ObjectType = 'ay'
  Begin
 	   SELECT us.Security_Id, us.User_Id,us.Group_Id,us.Access_Level,u.Is_Role
 	  	 FROM User_Security us
 	  	 Join users u on u.user_Id = us.user_Id and u.Role_Based_Security = 0
 	  	 Where  us.Group_Id = @Id 
  End
