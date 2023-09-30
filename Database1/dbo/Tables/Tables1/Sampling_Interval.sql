CREATE TABLE [dbo].[Sampling_Interval] (
    [SI_Id]   INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [SI_Desc] VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_Sampling_Interval] PRIMARY KEY NONCLUSTERED ([SI_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [Sampling_Interval_UC_Desc]
    ON [dbo].[Sampling_Interval]([SI_Desc] ASC);

