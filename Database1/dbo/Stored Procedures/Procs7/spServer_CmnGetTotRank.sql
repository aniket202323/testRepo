CREATE PROCEDURE dbo.spServer_CmnGetTotRank
@PU_Id int,
@Tot_Rank int OUTPUT
 AS
Select @Tot_Rank = Sum(Rank) From Variables_Base Where PU_Id = @PU_Id
If @Tot_Rank Is Null
  Select @Tot_Rank = 0
