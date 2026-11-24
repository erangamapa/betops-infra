# Eval report page

This folder deploys the static eval report. There is no build step.

The publish workflow in the evalgate repo renders its HTML report, copies it into `vercel/public/index.html` and deploys the folder. `vercel.json` points the output directory at `public` and turns every framework and build step off, so Vercel serves the files as they are.

To deploy by hand, copy a report into `public/` and run `vercel deploy --prod` from this folder. The project needs a `VERCEL_TOKEN` in the environment, never in the repo.

The `public/` folder is not committed. It is filled at publish time.
