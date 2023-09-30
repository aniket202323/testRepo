CREATE TABLE [dbo].[Spool_Weights] (
    [Spool_Id]     INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [PU_Id]        INT          NULL,
    [Spool_Code]   VARCHAR (20) NULL,
    [Spool_Weight] REAL         NOT NULL,
    CONSTRAINT [Spool_Weights_PK_SpoolId] PRIMARY KEY CLUSTERED ([Spool_Id] ASC),
    CONSTRAINT [Spool_Weights_FK_PUId] FOREIGN KEY ([PU_Id]) REFERENCES [dbo].[Prod_Units_Base] ([PU_Id])
);

