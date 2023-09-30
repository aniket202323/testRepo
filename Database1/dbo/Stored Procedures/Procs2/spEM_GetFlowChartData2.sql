CREATE PROCEDURE dbo.spEM_GetFlowChartData2
  @Id1 	  	 VarChar(7000),
  @Id2 	  	 int,
  @UnitId 	 int,
  @CharId 	 VarChar(7000),
  @ChartType 	 int,
  @TransId 	 int
-- Chart Type  0 - Normal Specification Window
--             1 - Central Specification
--             2 - Unit Configuration
  AS
DECLARE @MasterPU 	 Int,
 	 @Prop_Id 	 Int,
 	 @PUG_Id 	  	 Int,
 	 @Local_Spec 	 Int,
 	 @TransPropId    Int,
 	 @SpecId 	  	 Int,
 	 @PUId 	  	 Int
 	 
Create Table #PUs(PU_Id int)
Create Table #MasterPUs(PU_Id int)
IF @ChartType = 2
    BEGIN 
       SELECT @MasterPU  = @UnitId,@Prop_Id = Prop_Id
         FROM Characteristics
         WHERE Char_Id = @CharId
    END
 ELSE IF @ChartType = 0   --Id1 = Prod_id  --  id2 = var_id
    BEGIN 
       SELECT @PUG_Id = v.PUG_Id,@Prop_Id = s.Prop_Id
         FROM Variables v
         JOIN Specifications s ON s.Spec_Id = v.Spec_Id
         WHERE v.Var_Id = @Id2
       IF @PUG_Id IS NULL 
 	  SELECT @PUG_Id = PUG_Id FROM Variables WHERE Var_Id = @Id2
       SELECT @MasterPU = (SELECT Master_Unit FROM Prod_Units WHERE PU_Id = (SELECT PU_Id FROM PU_Groups where PUG_Id = @PUG_Id))
       IF @MasterPU IS NULL  Select @MasterPU = (SELECT PU_Id FROM PU_Groups where PUG_Id = @PUG_Id)
       Insert into #MasterPUs(PU_Id) Values(@MasterPU)
       IF @Prop_Id IS NULL
         BEGIN
          SELECT @Local_Spec = 0
         END
       ELSE
          SELECT @Local_Spec = 1
    END
ELSE IF @ChartType = 4
 	 Begin
        	     Select @Prop_Id = @UnitId
            Select @Local_Spec = 1 	   
 	     Declare Spec_Cursor Cursor 
 	       For Select Spec_Id From Specifications where Prop_Id = @Prop_Id
 	       For Read only
 	    Open Spec_Cursor
NextSpec:
 	    Fetch Next From Spec_Cursor into @SpecId
 	    If @@Fetch_Status  = 0 
 	       Begin
 	  	 Insert into #PUs
 	  	    Select PU_Id  From Variables where Spec_Id  = @SpecId
 	  	 Goto NextSpec
 	       End
 	    Close Spec_Cursor
 	    Deallocate Spec_Cursor
 	    Declare Pu_Cursor Cursor 
 	       For Select PU_Id From #PUs
 	       For Read only
 	    Open PU_Cursor
NextPU:
 	    Fetch Next From PU_Cursor into @PUId
 	    If @@Fetch_Status  = 0 
 	       Begin
 	  	 Insert into #MasterPUs
 	  	    Select Coalesce((Select Master_Unit From Prod_Units Where  PU_Id =  @PUId), @PUId)
 	  	 Goto NextPU
 	       End
 	    Close PU_Cursor
 	    Deallocate PU_Cursor
 	    Drop Table #PUs
 	 End
Else
   BEGIN --- type 1 -- id2 = specid and id1 = CharId  
       SELECT @Prop_Id = prop_Id from Characteristics WHERE Char_Id = Convert(int,@Id1)
       If @unitId is null 
 	 Select @MasterPU = 0
       Else
 	 Begin     
 	     SELECT @MasterPU = ((SELECT Master_Unit FROM Prod_Units WHERE PU_Id =  @unitId))
 	     IF @MasterPU IS NULL  Select @MasterPU =@unitId
 	 End
   END
IF @ChartType = 0 Or @ChartType = 4
  BEGIN
 	 --
 	 -- Property
 	 --
 	 SELECT Level1_Desc = Prop_Desc,Level1_Id = Prop_Id 
           	  	 FROM Product_Properties WHERE Prop_Id = @Prop_Id
 	 Declare @C Int
 	 Create Table #CharId(Char_Id Int)
 	 Create Table #CharId2(Char_Id Int)
IF  @ChartType = 4 
  Begin
 	 While (Datalength(LTRIM(RTRIM(@CharId))) > 1) 
 	   Begin
 	     Select @C = SubString(@CharId,1,CharIndex(Char(1),@CharId)-1)
 	     Insert Into #CharId2 (Char_Id) Values (@C)
 	     Select @CharId = SubString(@CharId,CharIndex(Char(1),@CharId),Datalength(@CharId))
 	     Select @CharId = Right(@CharId,Datalength(@CharId)-1)
 	   End
  End
Else
  Begin
 	 While (Datalength(LTRIM(RTRIM(@Id1))) > 1) 
 	   Begin
 	     Select @C = SubString(@Id1,1,CharIndex(Char(1),@Id1)-1)
 	     Insert Into #CharId2 (Char_Id) 
 	  	 Select Char_Id From Pu_Characteristics 
 	  	   Where Prod_Id = Convert(Int,@C) And pu_Id = @MasterPU AND Prop_Id = @Prop_Id
 	     Select @Id1 = SubString(@Id1,CharIndex(Char(1),@Id1),Datalength(@Id1))
 	     Select @Id1 = Right(@Id1,Datalength(@Id1)-1)
 	   End
  End
 	 /*
 	 Add All Parent Characteristics
 	 */
 	 CharLoop:
 	 Insert into #CharId2 
 	    Select Derived_From_Parent 
 	  	  	 From Characteristics 
 	  	  	 Where Derived_From_Parent is not null and  Derived_From_Parent Not In (Select Char_Id From #CharId2)
 	  	  	 And Char_Id In  (Select Char_Id From #CharId2)
 	 IF @@RowCount <> 0 GoTo CharLoop
 	 Insert Into  #CharId(Char_Id) Select Distinct Char_Id From #CharId2
 	 Select Level2_Id = c.Char_Id,Level2_Desc = c.Char_Desc,c.Derived_From_Parent
 	   From #CharId c1
 	   Join Characteristics c on c.Char_Id = c1.Char_Id 
 	 
 	 Create Table #Products(Level3_Desc nvarchar(25),Level3_Desc2 nVarChar(100),Level3_Id Int,Level3_Id3  int,Is_Trans  int,Prop_Id Int)
 	 Insert Into  #Products(Level3_Desc,Level3_Desc2,Level3_Id ,Level3_Id3,Is_Trans,Prop_Id)
 	       Select   Prod_Code, Prod_Desc, c.Char_Id, p.prod_id, null,c.Prop_Id
 	             From Characteristics c
 	  	     Left Join Pu_Characteristics pc on pc.PU_Id in (select Distinct pu_Id from #MasterPUs) And  pc.Prop_Id = @Prop_Id And pc.Char_Id = c.Char_Id
  	                 	 Join Products p on   pc.Prod_Id = p.Prod_Id
 	         	  	 WHERE c.Prop_Id = @Prop_Id and c.Char_Id In (Select Char_Id From #CharId)
 	  	 Declare Trans_Char_Cursor Cursor
 	  	 For Select  Prod_Id
 	  	   From Trans_Characteristics 
 	  	   Where PU_Id  in (select Distinct pu_Id from #MasterPUs)  And Prop_Id = @Prop_Id And Trans_Id = @TransId
 	  	 For Read Only
 	  	 Open Trans_Char_Cursor
 	 TransLoop:
 	  	 Fetch Next From Trans_Char_Cursor into @TransPropId
 	  	 If @@Fetch_status = 0
 	  	    Begin
 	  	       Delete From #Products
 	  	          Where Level3_Id3 = @TransPropId And Prop_Id = @Prop_Id
 	  	       GoTo TransLoop
 	  	    End
 	  	 Close Trans_Char_Cursor
 	  	 Deallocate Trans_Char_Cursor
 	  	 --
 	  	 -- Insert Transactions
 	  	 --
 	  	 Insert Into  #Products(Level3_Desc,Level3_Desc2,Level3_Id ,Level3_Id3,Is_Trans,Prop_Id)
 	  	       Select   Prod_Code, Prod_Desc, c.Char_Id, p.prod_id, 1,c.Prop_Id
 	                       From Characteristics c
 	         	           Left Join Trans_Characteristics pc on pc.PU_Id  in (select Distinct pu_Id from #MasterPUs)  And  pc.Prop_Id = @Prop_Id And pc.Char_Id = c.Char_Id  And Trans_Id = @TransId
  	                 	 Join Products p on   pc.Prod_Id = p.Prod_Id
 	         	  	 WHERE c.Prop_Id = @Prop_Id and c.Char_Id In (Select Char_Id From #CharId) 
 	   
 	 DECLARE  @Products Table (Id Int Identity(1,1),Level3_Desc nvarchar(25),Level3_Desc2 nVarChar(100),Level3_Id Int,Level3_Id3  int,Is_Trans  int,Prop_Id Int)
    INSERT INTO @Products(Level3_Desc , Level3_Desc2, Level3_Id , Level3_Id3,Is_Trans,Prop_Id)
 	  	 Select distinct Level3_Desc , Level3_Desc2, Level3_Id , Level3_Id3,Is_Trans,Prop_Id 
 	  	 from #Products 
 	  	 Drop Table #Products
 	  	 
 	  	 Select distinct Level3_Desc , Level3_Desc2, Level3_Id , Level3_Id3 = id,Is_Trans,Prop_Id 
 	  	 from @Products 
 	  	 Order by Level3_Id,Level3_Desc,Level3_Desc2
 	  	 --
 	  	 -- Deviations
 	  	 --
 	  	 SELECT Level2_Desc = Char_Desc,Level2_Id = Char_Id,DFP = Derived_From_Parent
 	  	   FROM Characteristics
 	  	   WHERE Prop_Id = @Prop_Id And Characteristic_Type =2
 	  	   ORDER BY Char_Id
                --
                -- FIRST Exceptions
                --
                SELECT Char_Id,Char_Desc,CT = Characteristic_Type,ET = Exception_Type,DFP = Derived_From_Parent
                  FROM  Characteristics
                  WHERE Prop_Id = @Prop_Id and characteristic_type = 3 and Derived_From_Parent is NOT NULL
 	           ORDER BY Characteristic_Type,Exception_Type,Derived_From_Parent
                --
                -- Next Exceptions
                --
                SELECT Char_Id,Char_Desc,CT = Characteristic_Type,ET = Exception_Type,DFE = Derived_From_Exception
                  FROM  Characteristics
                  WHERE Prop_Id = @Prop_Id and characteristic_type = 3 and Derived_From_Exception IS NOT NULL
 	           ORDER BY Characteristic_Type,Exception_Type,Derived_From_Parent
 	 --
 	 -- get transaction char links
 	 --
 	 Select * from Trans_Char_Links
 	    Join #CharId on  From_Char_Id = Char_Id 
 	    Where Trans_Id = @TransId
 	    Order by TransOrder
 	 Drop Table #CharId
 	 Drop Table #CharId2
 	         --
 	  	 -- Characteristic (For Highlight)
 	  	 --
 	   If @ChartType = 0
 	  	 SELECT Level2_Id = Char_Id FROM PU_Characteristics 
 	  	    WHERE PU_Id = @MasterPU AND Prop_Id = @Prop_Id AND Prod_Id = Convert(Int,@Id1)
 	  Else 
 	      SELECT Level2_Id = 1
  END
ELSE IF @ChartType = 1
  BEGIN
 	 --
 	 --  Characteristic
 	 --
 	 SELECT Level1_Desc = Char_Desc,Level1_Id = Char_Id
              FROM Characteristics
 	   WHERE  Char_Id = Convert(Int,@Id1)
 	  --
 	 --Products
 	 --
 	  	 Create Table #Prods(Prod_Desc nvarchar(50),Level3_Id3  int,Is_Trans  int,Prop_Id Int)
If @MasterPU <> 0 
 Begin
 	  	 Insert Into  #Prods(Prod_Desc ,Level3_Id3,Is_Trans,Prop_Id)
 	  	       Select   Prod_Desc,  p.prod_id, null,c.Prop_Id
 	                       From Characteristics c
 	         	           Left Join Pu_Characteristics pc on pc.PU_Id = @MasterPU And  pc.Prop_Id = @Prop_Id And pc.Char_Id = c.Char_Id
  	                 	 Join Products p on   pc.Prod_Id = p.Prod_Id
 	         	  	 WHERE  c.Char_Id = Convert(int,@Id1)
 	  	 Declare Trans_Char_Cursor Cursor
 	  	 For Select  Prod_Id
 	  	   From Trans_Characteristics 
 	  	   Where PU_Id = @MasterPU And Prop_Id = @Prop_Id And Trans_Id = @TransId
 	  	 For Read Only
 	  	 Open Trans_Char_Cursor
 	 TransLoop1:
 	  	 Fetch Next From Trans_Char_Cursor into @TransPropId
 	  	 If @@Fetch_status = 0 
 	  	    Begin
 	  	       Delete From #Prods
 	  	          Where Level3_Id3 = @TransPropId And Prop_Id = @Prop_Id
 	  	       GoTo TransLoop1
 	  	    End
 	  	 Close Trans_Char_Cursor
 	  	 Deallocate Trans_Char_Cursor
 	  	 --
 	  	 -- Insert Transactions
 	  	 --
 	  	 Insert Into  #Prods(Prod_Desc ,Level3_Id3,Is_Trans,Prop_Id)
 	  	       Select   Prod_Desc, p.prod_id, 1,c.Prop_Id
 	                       From Characteristics c
 	         	           Left Join Trans_Characteristics pc on pc.PU_Id = @MasterPU And  pc.Prop_Id = @Prop_Id And pc.Char_Id = c.Char_Id
  	                 	 Join Products p on   pc.Prod_Id = p.Prod_Id
 	         	  	 WHERE c.Char_Id = Convert(Int,@Id1) and pc.Trans_Id = @TransId
End 	 
 	  	 Select * from #Prods Order by Prod_Desc
 	  	 Drop Table #Prods
 	 --
 	 -- Specifications
 	 --
 	 SELECT Level2_Desc = Spec_Desc,Level2_Id = Spec_Id
 	   FROM Specifications WHERE Prop_Id = @Prop_Id
 	 --
 	 -- Variables
 	 --
 	 SELECT  Level3_Desc = v.Var_Desc,Level3_Desc2 = v.Var_Desc,Level3_Id = v.Spec_Id,Level3_Id2 = null
          FROM Specifications s
          JOIN Variables v ON s.Spec_Id = v.Spec_Id
        	   WHERE s.Prop_Id = @Prop_Id
 	   ORDER BY v.Spec_Id,v.Var_Desc
 	  --
 	 -- Specification (For Highlight)
 	 --
 	 SELECT Level2_Id =  @Id2
  END
ELSE
  BEGIN
 	 --
 	 -- Property
 	 --
 	 SELECT Level1_Desc = Prop_Desc,Level1_Id =Prop_Id FROM Product_Properties WHERE Prop_Id = @Prop_Id
 	 --
 	 --  Characteristics
 	 --
 	 SELECT Level2_Desc = Char_Desc,Level2_Id = Char_Id From Characteristics WHERE Prop_Id = @Prop_Id
 	 --
 	 -- Variables
 	 --
 	 SELECT DISTINCT Level3_Desc = v.Var_Desc,Level3_Id = c.Char_Id
          FROM PU_Characteristics c
          JOIN Specifications s ON s.Prop_Id = c.Prop_Id
          JOIN Variables v ON v.Spec_Id = s.Spec_Id
        	   WHERE c.Prop_Id = @Prop_Id ANd c.Pu_Id  = @MasterPU and Prod_Id = Convert(Int,@Id1)
 	   ORDER BY c.Char_Id,v.Var_Desc
             --
 	 -- Characteristic (For Highlight)
 	 --
 	 SELECT Level2_Id =  @CharId
  END
Drop Table #MasterPUs
GRANT  EXECUTE  ON [dbo].[spEM_GetFlowChartData2]  TO [ComXClient]
