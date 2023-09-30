CREATE PROCEDURE dbo.spEM_GetGroupPC
  @PUG_Id int,
  @Prod_Id int
  AS
  --
  DECLARE @Now          Datetime_ComX,
          @MasterPU     int,
 	   @pu_Id 	 Int
  --
  -- Initialize local variables.
  --
  Select @PU_Id = PU_Id FROM PU_Groups where PUG_Id = @PUG_Id
  SELECT @MasterPU = Coalesce((SELECT Master_Unit FROM Prod_Units WHERE PU_Id = @PU_Id),@PU_Id)
  SELECT Distinct s.Prop_Id,s.Spec_Id INTO #P 
 	 From Specifications s
 	 Join Product_Properties pp On pp.Prop_Id = s.Prop_Id and pp.Property_Type_Id = 1
 	 Where s.spec_id in (Select DISTINCT spec_Id FROM Variables WHERE  PU_Id IN(Select PU_Id from Prod_Units where   PU_Id =@MasterPU or Master_Unit = @MasterPU )) 
  SELECT c.Prop_Id,Char_Id,Spec_Id From PU_Characteristics c
  JOIN #P p on p.Prop_Id = c.Prop_Id
  WHERE Prod_Id = @Prod_Id AND PU_Id = @MasterPU AND c.Prop_Id IN (Select Prop_Id from #P)
  DROP TABLE #P
