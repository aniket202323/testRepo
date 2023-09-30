CREATE TABLE [dbo].[Dashboard_Gallery_Generator_Servers] (
    [dirtybit] BIT          CONSTRAINT [DF__dashboard__dirty__2E91A8E5] DEFAULT ((0)) NOT NULL,
    [Server]   VARCHAR (50) NOT NULL
);

