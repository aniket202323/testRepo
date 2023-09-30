Create Procedure dbo.spEMEV_LookupField
@ED_Field_Type_Id int, 
@Extended_Info nvarchar(255) = NULL,
@User_Id int
AS
If @Extended_Info = '' 
  Select @Extended_Info = NULL 
If @ED_Field_Type_Id = 8
  BEGIN
    Select ST_Id AS ID, ST_Desc AS 'Sampling Types' 
      From Sampling_Type
 	  Where ST_Id <> 48
      Order By ST_Desc ASC
  END
Else If @ED_Field_Type_Id = 9
  BEGIN
     If @Extended_Info = 'MASTER'
      BEGIN
        Select PU_Id AS ID, PU_Desc AS Units 
          From Prod_Units
          Where Master_Unit IS NULL 
            and PU_Id > 0 
          Order By Units ASC
      END
    Else 
      BEGIN
        Select Distinct PU_Id AS ID, PL_Desc + ' - ' + PU_Desc AS Units 
        From Prod_Units U
        Join Prod_Lines L on L.PL_Id = U.PL_Id
        Where PU_Id > 0
        Order By Units ASC
      END
  END
Else If @ED_Field_Type_Id = 10
  BEGIN
    If @Extended_Info IS NULL 
      BEGIN
        Select Var_Id AS ID, Var_Desc AS Variables
          From Variables
          Order By Var_Desc ASC
      END
    Else -- For specific master unit
      BEGIN
        Select Var_Id AS ID, Var_Desc AS Variables 
          From Variables v
          Join Prod_Units p on COALESCE(Master_Unit, p.PU_Id) = CONVERT(INT, @Extended_Info) and p.PU_Id = v.PU_Id 
          Order By Variables ASC
      END
  END
Else If @ED_Field_Type_Id = 13
  BEGIN
        Select WET_Id AS ID, WET_Name AS 'Waste Event Types'
          From Waste_Event_Type
          Order By [Waste Event Types] ASC
  END
Else If @ED_Field_Type_Id = 14
  BEGIN
    If @Extended_Info IS NULL 
      BEGIN
        Select WEMT_Id AS ID, WEMT_Name AS 'Waste Event Measurements'
          From Waste_Event_Meas
          Order By [Waste Event Measurements] ASC
 	  END
    ELSE
      BEGIN
        Select WEMT_Id AS ID, WEMT_Name AS 'Waste Event Measurements'
          From Waste_Event_Meas
 	  	 Where PU_Id = CONVERT(INT, @Extended_Info)
          Order By WEMT_Name ASC
 	  END
  END
Else If @ED_Field_Type_Id = 15
  BEGIN
    Select Event_Reason_Id AS ID, Event_Reason_Name AS Reasons 
      From Event_Reasons
    Order By Reasons ASC
  END
Else If @ED_Field_Type_Id = 16
  BEGIN
    Select ProdStatus_Id AS ID, ProdStatus_Desc AS 'Statuses' 
      From Production_Status
    Order By [Statuses] ASC
  END
Else If @ED_Field_Type_Id = 22
  BEGIN
    Select Spec_Id AS ID, Spec_Desc AS 'Specifications' 
      From Specifications
    Order By [Specifications] ASC
  END
Else If @ED_Field_Type_Id = 51
  BEGIN
    Select 1 AS ID, Name AS 'Local Stored Procedures' 
      From Sysobjects
      where Name like 'spLocal%'
    Order By [Local Stored Procedures] ASC
  END
Else If @ED_Field_Type_Id = 24
  BEGIN
    Select User_Id AS ID, Username AS 'Users' 
      From Users
    Order By [Users] ASC
  END
Else If @ED_Field_Type_Id = 25
  BEGIN
    Select Prod_Id AS ID, Prod_Code AS 'Products' 
      From Products
    Order By [Products] ASC
  END
Else If @ED_Field_Type_Id = 26
  BEGIN
    Select TEFault_Id AS ID, TEFault_Name AS 'Faults' 
      From Timed_Event_Fault
    Order By [Faults] ASC
  END
Else If @ED_Field_Type_Id = 60
  BEGIN
    	 Select [ID] = Field_Id, [Description] = Field_Desc  From ED_FieldType_ValidValues Where ED_Field_Type_Id = 60 order by Field_Desc
  END
Else If @ED_Field_Type_Id = 61
  BEGIN
    	 Select [ID] = Product_Family_Id, [Description] = Product_Family_Desc  From Product_Family Order By Product_Family_Desc
  END
Else If @ED_Field_Type_Id = 63
  BEGIN
    	 Select [ID] = DS_Id, [Description] = DS_Desc  From Data_Source Where DS_Id <> 50000 and Active = 1  order by DS_Desc
  END
Else If @ED_Field_Type_Id = 57 ---Code Added for Email Groups
BEGIN
 	 Select [ID] = EG_ID, [Email Groups] = EG_Desc
 	 From Email_Groups
 	 WHERE EG_ID <> 50
 	 Order by EG_Desc
END 
Else If @ED_Field_Type_Id = 59
BEGIN
 	 SELECT [ID] = Path_id , [Path Desc] = Path_Desc 
 	 From PrdExec_Paths 
 	 Order by Path_Desc
END 
