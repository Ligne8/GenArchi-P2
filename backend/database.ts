import { PrismaClient } from '@prisma/client';
import { Client } from 'pg';

const masterUrl = process.env.DATABASE_URL_MASTER!;
const standbyUrl = process.env.DATABASE_URL_STANDBY!;

async function checkConnection(url: string): Promise<boolean> {
  const client = new Client({ connectionString: url });
  try {
    await client.connect();
    return true;
  } catch (error) {
    if (error instanceof Error) {
      console.error(`Connexion échouée pour ${url}:`, error.message);
    } else {
      console.error(`Connexion échouée pour ${url}:`, error);
    }
    return false;
  } finally {
    await client.end();
  }
}

export async function createPrismaClient(): Promise<PrismaClient> {
  if (await checkConnection(masterUrl)) {
    console.log('Connexion réussie à la base de données principale.');
    return new PrismaClient({ datasources: { db: { url: masterUrl } } });
  } else if (await checkConnection(standbyUrl)) {
    console.warn('Basculement vers la base de données de secours.');
    return new PrismaClient({ datasources: { db: { url: standbyUrl } } });
  } else {
    throw new Error('Impossible de se connecter à aucune des bases de données.');
  }
}