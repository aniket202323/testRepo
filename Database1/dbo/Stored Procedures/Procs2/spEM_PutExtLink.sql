CREATE PROCEDURE dbo.spEM_PutExtLink
  @Object_Id     int,
  @Object_Type   nVarChar(2),
  @External_Link nvarchar(255),
  @Extended_Info nvarchar(255),
  @UseStartTime 	  Int,
  @User_Id int
 AS
  DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_PutExtLink',
                SUBSTRING(Convert(nVarChar(10),@Object_Id) + ','  + 
 	  	 @Object_Type + ','  + 
                LTRIM(RTRIM(@External_Link)) + ','  + 
                LTRIM(RTRIM(@Extended_Info)) + ','  + 
                Convert(nVarChar(10),@User_Id),1,255),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  --
  -- Return Codes:
  --
  --   0 = Success.
  --   1 = Error: Unknown object type.
  -- 
  -- Update the external link.
  IF @Object_Type = 'ad' 	 -- Production Line  'ad' 
    UPDATE Prod_Lines SET External_Link = @External_Link, Extended_Info = @Extended_Info WHERE PL_Id = @Object_Id
  ELSE IF @Object_Type = 'ae' 	 -- Production Unit 'ae'
    UPDATE Prod_Units SET External_Link = @External_Link, Extended_Info = @Extended_Info,Uses_Start_Time = @UseStartTime WHERE PU_Id = @Object_Id
  ELSE IF @Object_Type = 'af'  	 -- Production Group 'af'
    UPDATE PU_Groups SET External_Link = @External_Link WHERE PUG_Id = @Object_Id
  ELSE IF @Object_Type = 'ag' OR @Object_Type = 'ey' 	 -- Variable 'ag'
    UPDATE Variables_Base SET External_Link = @External_Link WHERE Var_Id = @Object_Id
  ELSE IF @Object_Type = 'aj' 	 -- Product 'aj'
    UPDATE Products SET External_Link = @External_Link, Extended_Info = @Extended_Info WHERE Prod_Id = @Object_Id
  ELSE IF @Object_Type = 'al' 	 -- Product Group 'al'
    UPDATE Product_Groups SET External_Link = @External_Link WHERE Product_Grp_Id = @Object_Id
  ELSE IF @Object_Type = 'ao' 	 -- Property 'ao'
    UPDATE Product_Properties SET External_Link = @External_Link WHERE Prop_Id = @Object_Id
  ELSE IF @Object_Type = 'aq' 	 -- Characterisitc 'aq'
    UPDATE Characteristics SET External_Link = @External_Link, Extended_Info = @Extended_Info WHERE Char_Id = @Object_Id
  ELSE IF @Object_Type = 'as' 	 -- Specification 'as'
    UPDATE Specifications SET External_Link = @External_Link,Extended_Info = @Extended_Info WHERE Spec_Id = @Object_Id
  ELSE IF @Object_Type = 'ay' 	 -- User Group 'ay'
    UPDATE Security_Groups SET External_Link = @External_Link WHERE Group_Id = @Object_Id
  ELSE IF @Object_Type = 'br'    -- Sheet 'br'
    UPDATE Sheets SET External_Link = @External_Link WHERE Sheet_Id = @Object_Id
  ELSE IF @Object_Type =  'bt'   -- Char Group  'bt'
    UPDATE Characteristic_Groups SET External_Link = @External_Link WHERE Characteristic_Grp_Id = @Object_Id
  ELSE IF @Object_Type =  'by'   -- Waste reason  'by'
    UPDATE Event_Reasons SET External_Link = @External_Link WHERE Event_Reason_Id = @Object_Id
  ELSE IF @Object_Type =  'cn'   -- Product Family  'cn'
    UPDATE Product_Family SET External_Link = @External_Link WHERE Product_Family_Id = @Object_Id
  ELSE IF @Object_Type =  'dz'   -- Department  'dz'
    UPDATE Departments SET  Extended_Info = @Extended_Info WHERE Dept_Id = @Object_Id
  ELSE 	  	  	 -- Unknown object type.
 	 BEGIN
 	     UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1 WHERE Audit_Trail_Id = @Insert_Id
 	     RETURN(1)
 	 END
  --
  -- Commit the transaction and return success.
  --
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
