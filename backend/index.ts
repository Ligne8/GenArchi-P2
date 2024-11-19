import express, { Request, Response, NextFunction } from "express";
import { PrismaClient } from "@prisma/client";
import { Client } from "pg";
import cors from "cors";
import { stringify } from "querystring";

const app = express();
app.use(cors());
app.use(express.json());

const masterUrl = process.env.DATABASE_URL_MASTER!;
const standbyUrl = process.env.DATABASE_URL_STANDBY!;

// Singleton pour les clients Prisma
const prismaClients = {
  master: new PrismaClient({ datasources: { db: { url: masterUrl } } }),
  standby: new PrismaClient({ datasources: { db: { url: standbyUrl } } }),
};

// Fonction pour vérifier la connexion
async function isDatabaseAccessible(url: string): Promise<boolean> {
  const client = new Client({ connectionString: url });
  try {
    await client.connect();
    return true;
  } catch (error) {
    console.error(`Échec de connexion pour ${url}:`, error);
    return false;
  } finally {
    await client.end();
  }
}

// Middleware pour sélectionner le client Prisma actif
app.use(async (req: Request, res: Response, next: NextFunction) => {
  const isMasterAccessible = await isDatabaseAccessible(masterUrl);
  req.prisma = isMasterAccessible ? prismaClients.master : prismaClients.standby;

  if (!isMasterAccessible) {
    console.warn("Basculement vers la base de données de secours.");
  } else {
    console.log("Connexion à la base de données principale réussie.");
  }

  next();
});

// Route pour créer un membre
app.post("/members", async (req: Request, res: Response) => {
  console.log(req.body);
  const { name, role, image } = req.body;
  try {
    const newMember = await req.prisma.member.create({
      data: { name, role, image },
    });
    res.status(201).json(newMember);
  } catch (error) {
    res.status(400).json({ error: `Erreur lors de la création du membre : ${error}` });
  }
});

// Route pour récupérer tous les membres
app.get("/members", async (req: Request, res: Response) => {
  try {
    const members = await req.prisma.member.findMany();
    res.json(members);
  } catch (error) {
    res.status(500).json({ error: `Erreur lors de la récupération des membres : ${error}` });
  }
});

// Route pour supprimer un membre
app.delete("/members/:name", async (req: Request, res: Response) => {
  const { name } = req.params;
  try {
    await req.prisma.member.delete({
      where: { name: name },
    });
    res.json({ message: "Membre supprimé avec succès" });
  } catch (error) {
    res.status(500).json({ error: `Erreur lors de la suppression du membre : ${error}` });
  }
});

app.get("/health", async (req: Request, res: Response) => {
  const isMasterAccessible = await isDatabaseAccessible(masterUrl);
  res.status(200).json({ isMasterAccessible });
});

function intensiveTask(n: any): any {
  if (n <= 1) return n;
  return intensiveTask(n - 1) + intensiveTask(n - 2);
}

// Endpoint générant une charge CPU
app.get("/stress", (req: Request, res: Response) => {
  const number = parseInt(req.query.n as string) || 35;
  console.log(`Processing Fibonacci(${number})`);
  const result = intensiveTask(number);
  res.send(`Fibonacci(${number}) = ${result}`);
});

const PORT = process.env.PORT || 4000;
app.listen(PORT, () => {
  console.log(`Serveur en écoute sur le port ${PORT}`);
});
