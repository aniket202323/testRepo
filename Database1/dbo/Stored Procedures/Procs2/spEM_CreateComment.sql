CREATE PROCEDURE dbo.spEM_CreateComment
  @Object_Id   int,
  @Object_Type varchar (2),
  @User_Id     int,
  @CS_Id       int,
  @Comment_Id  int OUTPUT
  AS
  --
  --
  -- Return Codes:
  --
  --   0 = Success.
  --   1 = Error: Can't create comment.
  --   2 = Error: Unknown object type.
  --
  -- Begin a transaction.
  --
 DECLARE @Insert_Id integer 
Insert into Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_CreateComment',
                 convert(nVarChar(10),@Object_Id) + ','  + @Object_Type + ',' + Convert(nVarChar(10), @User_Id) + ','  + Convert(nVarChar(10),  @CS_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
select @Insert_Id = Scope_Identity()
 BEGIN TRANSACTION
  --
  -- Create the comment.
  --
  INSERT Comments(Comment, User_Id, Modified_On, CS_Id) VALUES(' ', @User_Id, dbo.fnServer_CmnGetDate(getUTCdate()), @CS_Id)
  SELECT @Comment_Id = Scope_Identity()
  IF @Comment_Id IS NULL
    BEGIN
      ROLLBACK TRANSACTION
     Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1 where Audit_Trail_Id = @Insert_Id
     RETURN(1)
    END
  --
  -- Give the object a reference to the comment.
  --
  IF @Object_Type = 'ad' 	 -- Production Line  'ad' 
    UPDATE Prod_Lines SET Comment_Id = @Comment_Id WHERE PL_Id = @Object_Id
  ELSE IF @Object_Type = 'ae' 	 -- Production Unit 'ae'
    UPDATE Prod_Units SET Comment_Id = @Comment_Id WHERE PU_Id = @Object_Id
  ELSE IF @Object_Type = 'af'  	 -- Production Group 'af'
    UPDATE PU_Groups SET Comment_Id = @Comment_Id WHERE PUG_Id = @Object_Id
  ELSE IF @Object_Type = 'ag' 	 -- Variable 'ag'
    UPDATE Variables_Base SET Comment_Id = @Comment_Id WHERE Var_Id = @Object_Id
  ELSE IF @Object_Type = 'aj' 	 -- Product 'aj'
    UPDATE Products SET Comment_Id = @Comment_Id WHERE Prod_Id = @Object_Id
  ELSE IF @Object_Type = 'al' 	 -- Product Group 'al'
    UPDATE Product_Groups SET Comment_Id = @Comment_Id WHERE Product_Grp_Id = @Object_Id
  ELSE IF @Object_Type = 'ao' 	 -- Property 'ao'
    UPDATE Product_Properties SET Comment_Id = @Comment_Id WHERE Prop_Id = @Object_Id
  ELSE IF @Object_Type = 'aq' 	 -- Characterisitc 'aq'
    UPDATE Characteristics SET Comment_Id = @Comment_Id WHERE Char_Id = @Object_Id
  ELSE IF @Object_Type = 'as' 	 -- Specification 'as'
    UPDATE Specifications SET Comment_Id = @Comment_Id WHERE Spec_Id = @Object_Id
  ELSE IF @Object_Type = 'ay' 	 -- User Group 'ay'
    UPDATE Security_Groups SET Comment_Id = @Comment_Id WHERE Group_Id = @Object_Id
  ELSE IF @Object_Type = 'bg'   -- transaction 'bg'
    UPDATE Transactions SET Comment_Id = @Comment_Id WHERE Trans_Id = @Object_Id
  ELSE IF @Object_Type = 'br'    -- Sheet 'br'
    UPDATE Sheets SET Comment_Id = @Comment_Id WHERE Sheet_Id = @Object_Id
  ELSE IF @Object_Type =  'bt'   -- Char Group  'bt'
    UPDATE Characteristic_Groups SET Comment_Id = @Comment_Id WHERE Characteristic_Grp_Id = @Object_Id
  ELSE IF @Object_Type =  'by'   -- Waste reason  'by'
    UPDATE Event_Reasons SET Comment_Id = @Comment_Id WHERE Event_Reason_Id = @Object_Id
  ELSE IF @Object_Type =  'cn'   -- Product Family
    UPDATE Product_Family SET Comment_Id = @Comment_Id WHERE Product_Family_Id = @Object_Id
  ELSE IF @Object_Type =  'dz'   -- Department
    UPDATE Departments SET Comment_Id = @Comment_Id WHERE Dept_Id = @Object_Id
  ELSE IF @Object_Type =  'fk'   -- BOM Family
    UPDATE Bill_Of_Material_Family SET Comment_Id = @Comment_Id WHERE BOM_Family_Id = @Object_Id
  ELSE IF @Object_Type =  'fm'   -- BOM
    UPDATE Bill_Of_Material SET Comment_Id = @Comment_Id WHERE BOM_Id = @Object_Id
  ELSE IF @Object_Type =  'fn'   -- BOM Formulation
    UPDATE Bill_Of_Material_Formulation SET Comment_Id = @Comment_Id WHERE BOM_Formulation_Id = @Object_Id
  ELSE IF @Object_Type =  'fo'   -- BOM Formulation Item
    UPDATE Bill_Of_Material_Formulation_Item SET Comment_Id = @Comment_Id WHERE BOM_Formulation_Item_Id = @Object_Id
  ELSE 	  	  	  	 -- Unknown object type.
    BEGIN
      ROLLBACK TRANSACTION
      Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 2 where Audit_Trail_Id = @Insert_Id 
      RETURN(2)
    END
  --
  -- Commit the transaction and return success.
  --
  COMMIT TRANSACTION
  Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0,Output_Parameters = convert(nVarChar(10),@Comment_Id) where Audit_Trail_Id = @Insert_Id
RETURN(0)
