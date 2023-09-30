CREATE TABLE [dbo].[SDK_Clause_Data] (
    [ClauseDataId]      INT            IDENTITY (1, 1) NOT NULL,
    [ClauseId]          INT            NOT NULL,
    [SDKVersion]        VARCHAR (100)  NOT NULL,
    [ObjectId]          INT            NOT NULL,
    [ClauseGroupNumber] INT            NULL,
    [ClauseData]        VARCHAR (8000) NULL,
    CONSTRAINT [SDK_Clause_Data_PK_ClauseDataId] PRIMARY KEY CLUSTERED ([ClauseDataId] ASC),
    CONSTRAINT [SDK_Clause_Data_FK_ClauseId] FOREIGN KEY ([ClauseId]) REFERENCES [dbo].[SDK_Clause_Types] ([ClauseId]),
    CONSTRAINT [SDK_Clause_Data_FK_ObjectId] FOREIGN KEY ([ObjectId]) REFERENCES [dbo].[SDK_Objects] ([ObjectId])
);

