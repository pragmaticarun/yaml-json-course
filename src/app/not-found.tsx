import Link from "next/link";

export default function NotFound() {
  return (
    <div className="mx-auto max-w-xl">
      <h1 className="font-serif text-4xl">That page is not in the course</h1>
      <p className="mt-3 leading-7">
        The site is a static export and only contains the lessons and pages generated from this
        repository.
      </p>
      <Link className="mt-4 inline-block underline" href="/">
        Back to the course
      </Link>
    </div>
  );
}
