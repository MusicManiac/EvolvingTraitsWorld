import argparse
import re
from pathlib import Path


MOD_ROOT = (
	Path(__file__).resolve().parent
	/ "Contents"
	/ "mods"
	/ "Evolving Traits World"
)

GLUED_AFTER = {
	"HealerSystemSleepingMultiplier": [
		"InjuriesSystem",
		"InjuriesSystemCounter",
		"InjuriesSystemPassiveCounterDecay",
		"BodyBiteContribution",
		"BodyBurnContribution",
		"BodyDeepWoundContribution",
		"BodyFractureContribution",
		"BodyLacerationContribution",
		"BodyLodgedBulletContribution",
		"BodyLodgedGlassContribution",
		"BodyScratchContribution",
	],
	"TemperatureTraitsEffectMultiplier": [
		"ColdTraitsTemperatureThreshold",
		"HeatTraitsTemperatureThreshold",
	],
	"BurnWardPatientChanceOneIn": [
		"WildernessKnowledge",
		"WildernessKnowledgeSkill",
	]
}


def get_version(path):
	match = re.fullmatch(r"(\d+)\.(\d+)", path.name)
	if not match:
		return None

	return tuple(map(int, match.groups()))


def find_sandbox_options():
	candidates = []

	for path in MOD_ROOT.iterdir():
		if not path.is_dir():
			continue

		version = get_version(path)
		if version is None:
			continue

		sandbox_options = path / "media" / "sandbox-options.txt"

		if sandbox_options.is_file():
			candidates.append((version, sandbox_options))

	if not candidates:
		raise FileNotFoundError(
			f"Could not find sandbox-options.txt under {MOD_ROOT}"
		)

	# Use the highest version, e.g. 42.12 over 42.11.
	candidates.sort(key=lambda item: item[0])

	return candidates[-1][1]


def get_option_name(block):
	match = re.match(
		r"option EvolvingTraitsWorld\.([^\s{]+)",
		block,
	)

	if not match:
		return ""

	return match.group(1)


def is_section(block):
	return re.search(
		r"^\s*type\s*=",
		block,
		re.MULTILINE,
	) is None


def sort_section(blocks):
	blocks_by_name = {
		get_option_name(block): block
		for block in blocks
	}

	glued_names = {
		name
		for names in GLUED_AFTER.values()
		for name in names
	}

	normal_blocks = [
		block
		for block in blocks
		if get_option_name(block) not in glued_names
	]

	normal_blocks.sort(
		key=lambda block: get_option_name(block).lower()
	)

	result = []

	for block in normal_blocks:
		result.append(block)

		name = get_option_name(block)

		for glued_name in GLUED_AFTER.get(name, []):
			glued_block = blocks_by_name.get(glued_name)

			if glued_block is not None:
				result.append(glued_block)

	return result


def sorted_sandbox_options(text):
	first_option = text.find("option EvolvingTraitsWorld.")

	if first_option == -1:
		raise ValueError("No EvolvingTraitsWorld options found")

	prefix = text[:first_option]

	blocks = re.findall(
		r"option EvolvingTraitsWorld\.[^{\s]+\s*\{.*?\}",
		text[first_option:],
		flags=re.DOTALL,
	)

	result = []
	current_header = None
	current_section = []

	def flush_section():
		nonlocal current_section

		if current_header is not None:
			result.append(current_header)

		result.extend(sort_section(current_section))
		current_section = []

	for block in blocks:
		if is_section(block):
			flush_section()
			current_header = block
		else:
			current_section.append(block)

	flush_section()

	return prefix + "\n".join(result) + "\n"


def parse_args():
	parser = argparse.ArgumentParser(
		description="Sort sandbox options alphabetically within each section.",
	)
	parser.add_argument(
		"--check",
		action="store_true",
		help="report an unsorted file without changing it",
	)
	return parser.parse_args()


def main():
	args = parse_args()
	sandbox_options = find_sandbox_options()
	original = sandbox_options.read_text(encoding="utf-8")

	try:
		formatted = sorted_sandbox_options(original)
	except ValueError as error:
		raise ValueError(
			f"Could not process {sandbox_options}: {error}"
		) from error

	if formatted == original:
		print(f"Already sorted: {sandbox_options}")
		return 0

	if args.check:
		print(f"Not sorted: {sandbox_options}")
		return 1

	sandbox_options.write_text(
		formatted,
		encoding="utf-8",
	)
	print(f"Sorted: {sandbox_options}")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
